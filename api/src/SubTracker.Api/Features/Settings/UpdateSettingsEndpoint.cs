using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Settings.Domain;

namespace SubTracker.Api.Features.Settings;

public sealed class UpdateSettingsEndpoint : Endpoint<UpdateSettingsEndpoint.Request>
{
    public sealed class Request
    {
        public string BaseCurrency { get; init; } = string.Empty;
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.BaseCurrency)
                .NotEmpty().WithMessage("Base currency is required")
                .Must(c => UserSettings.SupportedCurrencies.Contains(c.ToUpperInvariant()))
                .WithMessage($"Base currency must be one of: {string.Join(", ", UserSettings.SupportedCurrencies)}");
        }
    }

    private readonly AppDbContext _db;
    private readonly IDateTimeProvider _dateTime;
    private readonly ILogger<UpdateSettingsEndpoint> _logger;

    public UpdateSettingsEndpoint(AppDbContext db, IDateTimeProvider dateTime, ILogger<UpdateSettingsEndpoint> logger)
    {
        _db = db;
        _dateTime = dateTime;
        _logger = logger;
    }

    public override void Configure()
    {
        Put("/api/settings");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = _dateTime.UtcNow;

        // TODO: Replace with User.GetUserId() from JWT claims when auth is integrated
        var userId = Guid.Empty;
        var settings = await _db.UserSettings.FirstOrDefaultAsync(s => s.UserId == userId, ct);

        if (settings is null)
        {
            settings = UserSettings.CreateDefault(userId, utcNow);
            _db.UserSettings.Add(settings);
        }

        settings.UpdateBaseCurrency(req.BaseCurrency, utcNow);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User settings updated: BaseCurrency={BaseCurrency}", settings.BaseCurrency);

        await Send.NoContentAsync(ct);
    }
}