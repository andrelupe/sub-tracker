using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Settings.Domain;

namespace SubTracker.Api.Features.Settings;

public sealed class GetSettingsEndpoint : EndpointWithoutRequest<GetSettingsEndpoint.Response>
{
    public new sealed class Response
    {
        public string BaseCurrency { get; init; } = string.Empty;
        public DateTime UpdatedAt { get; init; }
    }

    private readonly AppDbContext _db;
    private readonly IDateTimeProvider _dateTime;

    public GetSettingsEndpoint(AppDbContext db, IDateTimeProvider dateTime)
    {
        _db = db;
        _dateTime = dateTime;
    }

    public override void Configure()
    {
        Get("/api/settings");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var settings = await _db.UserSettings.FirstOrDefaultAsync(ct);

        if (settings is null)
        {
            settings = UserSettings.CreateDefault(_dateTime.UtcNow);
            _db.UserSettings.Add(settings);
            await _db.SaveChangesAsync(ct);
        }

        await Send.OkAsync(new Response
        {
            BaseCurrency = settings.BaseCurrency,
            UpdatedAt = settings.UpdatedAt
        }, ct);
    }
}
