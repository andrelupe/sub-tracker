using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Subscriptions.Domain;
using static SubTracker.Api.Features.Subscriptions.ImportEndpoint;

namespace SubTracker.Api.Tests.Features.Subscriptions;

public class ImportEndpointTests : IDisposable
{
    private readonly DateTime _utcNow = new(2026, 2, 6, 12, 0, 0, DateTimeKind.Utc);
    private readonly AppDbContext _db;
    private readonly FakeDateTimeProvider _dateTime;

    public ImportEndpointTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite("DataSource=:memory:")
            .Options;

        _db = new AppDbContext(options);
        _db.Database.OpenConnection();
        _db.Database.EnsureCreated();

        _dateTime = new FakeDateTimeProvider(_utcNow);
    }

    public void Dispose()
    {
        _db.Database.CloseConnection();
        _db.Dispose();
    }

    // --- Helper to run import logic (mirrors endpoint HandleAsync) ---

    private async Task<Response> ExecuteImport(Request req)
    {
        var errors = new List<ImportError>();
        var subscriptionsToCreate = new List<Subscription>();

        for (var i = 0; i < req.Subscriptions.Count; i++)
        {
            var dto = req.Subscriptions[i];

            var validationError = ValidateDto(dto);
            if (validationError is not null)
            {
                errors.Add(new ImportError { Index = i, Message = validationError });
                continue;
            }

            var subscription = Subscription.Create(
                dto.Name,
                dto.Description,
                dto.Amount,
                dto.Currency,
                Enum.Parse<BillingCycle>(dto.BillingCycle),
                Enum.Parse<SubscriptionCategory>(dto.Category),
                dto.StartDate,
                dto.Url,
                dto.ReminderDaysBefore,
                _dateTime.UtcNow
            );

            if (!dto.IsActive)
                subscription.Deactivate(_dateTime.UtcNow);

            subscriptionsToCreate.Add(subscription);
        }

        if (errors.Count > 0)
        {
            return new Response
            {
                Imported = 0,
                Errors = errors
            };
        }

        _db.Subscriptions.AddRange(subscriptionsToCreate);
        await _db.SaveChangesAsync();

        return new Response
        {
            Imported = subscriptionsToCreate.Count,
            Errors = []
        };
    }

    private static readonly HashSet<string> ValidCurrencies = ["EUR", "USD", "GBP"];

    private string? ValidateDto(SubscriptionImportDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            return "Name is required";

        if (dto.Name.Length > 100)
            return "Name must not exceed 100 characters";

        if (dto.Amount <= 0)
            return "Amount must be greater than 0";

        if (!ValidCurrencies.Contains(dto.Currency))
            return $"Invalid currency: {dto.Currency}. Must be one of: EUR, USD, GBP";

        if (!Enum.TryParse<BillingCycle>(dto.BillingCycle, out _))
            return $"Invalid billing cycle: {dto.BillingCycle}. Must be one of: Weekly, Monthly, Quarterly, Yearly";

        if (!Enum.TryParse<SubscriptionCategory>(dto.Category, out _))
            return $"Invalid category: {dto.Category}. Must be one of: {string.Join(", ", Enum.GetNames<SubscriptionCategory>())}";

        if (dto.StartDate == default)
            return "Start date is required";

        if (dto.StartDate > _dateTime.UtcNow.AddYears(1))
            return "Start date cannot be more than 1 year in the future";

        if (dto.ReminderDaysBefore < 0 || dto.ReminderDaysBefore > 30)
            return "Reminder days before must be between 0 and 30";

        return null;
    }

    // --- Tests ---

    [Fact]
    public async Task Import_ValidList_ShouldImportAll()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Netflix",
                    Description = "Streaming service",
                    Amount = 15.99m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Entertainment",
                    StartDate = new DateTime(2024, 1, 15),
                    Url = "https://netflix.com",
                    ReminderDaysBefore = 2,
                    IsActive = true
                },
                new SubscriptionImportDto
                {
                    Name = "Spotify",
                    Amount = 9.99m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Music",
                    StartDate = new DateTime(2024, 2, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(2, response.Imported);
        Assert.Empty(response.Errors);

        var dbSubscriptions = await _db.Subscriptions.ToListAsync();
        Assert.Equal(2, dbSubscriptions.Count);
        Assert.Contains(dbSubscriptions, s => s.Name == "Netflix");
        Assert.Contains(dbSubscriptions, s => s.Name == "Spotify");
    }

    [Fact]
    public async Task Import_WithInvalidItem_ShouldImportNone_Atomic()
    {
        // Arrange - second item has empty name
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Netflix",
                    Amount = 15.99m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Entertainment",
                    StartDate = new DateTime(2024, 1, 15)
                },
                new SubscriptionImportDto
                {
                    Name = "",
                    Amount = 9.99m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Music",
                    StartDate = new DateTime(2024, 2, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert - nothing imported (atomic)
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal(1, response.Errors[0].Index);
        Assert.Equal("Name is required", response.Errors[0].Message);

        // Verify DB is empty
        var count = await _db.Subscriptions.CountAsync();
        Assert.Equal(0, count);
    }

    [Fact]
    public async Task Import_EmptyList_ShouldReturnZeroImported()
    {
        // Arrange
        var request = new Request { Subscriptions = [] };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Empty(response.Errors);
    }

    [Fact]
    public async Task Import_MissingName_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "  ",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal(0, response.Errors[0].Index);
        Assert.Equal("Name is required", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_InvalidAmount_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 0m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal("Amount must be greater than 0", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_NegativeAmount_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = -5m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal("Amount must be greater than 0", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_InvalidCurrency_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 10m,
                    Currency = "ABC",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Contains("Invalid currency: ABC", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_InvalidBillingCycle_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "BiWeekly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Contains("Invalid billing cycle: BiWeekly", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_InvalidCategory_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "InvalidCategory",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Contains("Invalid category: InvalidCategory", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_ReminderDaysBelowRange_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1),
                    ReminderDaysBefore = -1
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal("Reminder days before must be between 0 and 30", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_ReminderDaysAboveRange_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1),
                    ReminderDaysBefore = 31
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal("Reminder days before must be between 0 and 30", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_StartDateTooFarInFuture_ShouldReturnError()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = _utcNow.AddYears(1).AddDays(1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Single(response.Errors);
        Assert.Equal("Start date cannot be more than 1 year in the future", response.Errors[0].Message);
    }

    [Fact]
    public async Task Import_MultipleErrors_ShouldReportAll()
    {
        // Arrange - items at index 0 and 2 are invalid
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                },
                new SubscriptionImportDto
                {
                    Name = "Valid",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                },
                new SubscriptionImportDto
                {
                    Name = "Test",
                    Amount = -1m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(0, response.Imported);
        Assert.Equal(2, response.Errors.Count);
        Assert.Equal(0, response.Errors[0].Index);
        Assert.Equal("Name is required", response.Errors[0].Message);
        Assert.Equal(2, response.Errors[1].Index);
        Assert.Equal("Amount must be greater than 0", response.Errors[1].Message);

        // Verify DB has no records
        var count = await _db.Subscriptions.CountAsync();
        Assert.Equal(0, count);
    }

    [Fact]
    public async Task Import_InactiveSubscription_ShouldSetIsActiveFalse()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Cancelled Sub",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1),
                    IsActive = false
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(1, response.Imported);
        Assert.Empty(response.Errors);

        var subscription = await _db.Subscriptions.SingleAsync();
        Assert.Equal("Cancelled Sub", subscription.Name);
        Assert.False(subscription.IsActive);
    }

    [Fact]
    public async Task Import_ShouldGenerateNewIds()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Sub 1",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                },
                new SubscriptionImportDto
                {
                    Name = "Sub 2",
                    Amount = 20m,
                    Currency = "USD",
                    BillingCycle = "Yearly",
                    Category = "Entertainment",
                    StartDate = new DateTime(2024, 6, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(2, response.Imported);

        var subscriptions = await _db.Subscriptions.ToListAsync();
        Assert.Equal(2, subscriptions.Count);

        // All IDs should be unique and not empty
        Assert.All(subscriptions, s => Assert.NotEqual(Guid.Empty, s.Id));
        Assert.NotEqual(subscriptions[0].Id, subscriptions[1].Id);
    }

    [Fact]
    public async Task Import_ShouldCalculateNextBillingDate()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Monthly Sub",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2026, 1, 15) // Next billing: Feb 15
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(1, response.Imported);

        var subscription = await _db.Subscriptions.SingleAsync();
        Assert.Equal(new DateTime(2026, 2, 15), subscription.NextBillingDate);
    }

    [Fact]
    public async Task Import_AllValidCurrencies_ShouldSucceed()
    {
        // Arrange
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "EUR Sub",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                },
                new SubscriptionImportDto
                {
                    Name = "USD Sub",
                    Amount = 10m,
                    Currency = "USD",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                },
                new SubscriptionImportDto
                {
                    Name = "GBP Sub",
                    Amount = 10m,
                    Currency = "GBP",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(3, response.Imported);
        Assert.Empty(response.Errors);
    }

    [Fact]
    public async Task Import_AllValidBillingCycles_ShouldSucceed()
    {
        // Arrange
        var cycles = new[] { "Weekly", "Monthly", "Quarterly", "Yearly" };
        var request = new Request
        {
            Subscriptions = cycles.Select(c => new SubscriptionImportDto
            {
                Name = $"{c} Sub",
                Amount = 10m,
                Currency = "EUR",
                BillingCycle = c,
                Category = "Other",
                StartDate = new DateTime(2024, 1, 1)
            }).ToList()
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(4, response.Imported);
        Assert.Empty(response.Errors);
    }

    [Fact]
    public async Task Import_AllValidCategories_ShouldSucceed()
    {
        // Arrange
        var categories = Enum.GetNames<SubscriptionCategory>();
        var request = new Request
        {
            Subscriptions = categories.Select(c => new SubscriptionImportDto
            {
                Name = $"{c} Sub",
                Amount = 10m,
                Currency = "EUR",
                BillingCycle = "Monthly",
                Category = c,
                StartDate = new DateTime(2024, 1, 1)
            }).ToList()
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert
        Assert.Equal(categories.Length, response.Imported);
        Assert.Empty(response.Errors);
    }

    [Fact]
    public async Task Import_DbShouldBeEmptyAfterValidationFailure()
    {
        // Arrange - pre-populate DB with one existing subscription
        var existing = Subscription.Create(
            "Existing",
            null,
            10m,
            "EUR",
            BillingCycle.Monthly,
            SubscriptionCategory.Other,
            new DateTime(2024, 1, 1),
            null,
            2,
            _utcNow
        );
        _db.Subscriptions.Add(existing);
        await _db.SaveChangesAsync();

        var countBefore = await _db.Subscriptions.CountAsync();

        // Attempt import with invalid data
        var request = new Request
        {
            Subscriptions =
            [
                new SubscriptionImportDto
                {
                    Name = "Valid New Sub",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                },
                new SubscriptionImportDto
                {
                    Name = "",
                    Amount = 10m,
                    Currency = "EUR",
                    BillingCycle = "Monthly",
                    Category = "Other",
                    StartDate = new DateTime(2024, 1, 1)
                }
            ]
        };

        // Act
        var response = await ExecuteImport(request);

        // Assert - DB count should be unchanged
        var countAfter = await _db.Subscriptions.CountAsync();
        Assert.Equal(0, response.Imported);
        Assert.Equal(countBefore, countAfter);
    }

    // --- Fake IDateTimeProvider ---

    private sealed class FakeDateTimeProvider(DateTime utcNow) : IDateTimeProvider
    {
        public DateTime UtcNow => utcNow;
    }
}
