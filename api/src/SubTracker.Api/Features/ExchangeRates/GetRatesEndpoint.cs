using FastEndpoints;
using SubTracker.Api.Common;

namespace SubTracker.Api.Features.ExchangeRates;

public sealed class GetRatesEndpoint : Endpoint<GetRatesEndpoint.Request, GetRatesEndpoint.Response>
{
    public sealed class Request
    {
        [QueryParam]
        public string Base { get; init; } = "EUR";
    }

    public new sealed class Response
    {
        public string Base { get; init; } = string.Empty;
        public string Date { get; init; } = string.Empty;
        public Dictionary<string, decimal> Rates { get; init; } = new();
    }

    private readonly IExchangeRateService _exchangeRateService;
    private readonly IDateTimeProvider _dateTime;

    public GetRatesEndpoint(IExchangeRateService exchangeRateService, IDateTimeProvider dateTime)
    {
        _exchangeRateService = exchangeRateService;
        _dateTime = dateTime;
    }

    public override void Configure()
    {
        Get("/api/exchange-rates");
        Roles(Auth.Domain.UserRole.Admin.ToString(), Auth.Domain.UserRole.User.ToString());
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var baseCurrency = req.Base.ToUpperInvariant();
        var rates = await _exchangeRateService.GetRatesAsync(baseCurrency, ct);

        await Send.OkAsync(new Response
        {
            Base = baseCurrency,
            Date = DateOnly.FromDateTime(_dateTime.UtcNow).ToString("yyyy-MM-dd"),
            Rates = rates
        }, ct);
    }
}