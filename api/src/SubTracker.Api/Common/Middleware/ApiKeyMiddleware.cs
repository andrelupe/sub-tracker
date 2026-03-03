namespace SubTracker.Api.Common.Middleware;

public sealed class ApiKeyMiddleware
{
    private const string ApiKeyHeaderName = "X-Api-Key";

    private static readonly string[] ExcludedPaths = ["/health", "/swagger"];

    private readonly RequestDelegate _next;
    private readonly string _apiKey;
    private readonly ILogger<ApiKeyMiddleware> _logger;

    public ApiKeyMiddleware(
        RequestDelegate next,
        IConfiguration configuration,
        ILogger<ApiKeyMiddleware> logger)
    {
        _next = next;
        _apiKey = configuration["ApiKey"] ?? string.Empty;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            await _next(context);
            return;
        }

        var path = context.Request.Path.Value ?? string.Empty;

        if (IsExcludedPath(path))
        {
            await _next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue(ApiKeyHeaderName, out var providedKey) ||
            providedKey.ToString() != _apiKey)
        {
            _logger.LogWarning(
                "Unauthorized API request from {RemoteIp} to {Path}",
                context.Connection.RemoteIpAddress,
                path);

            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsync("{\"error\":\"Invalid API key\"}");
            return;
        }

        await _next(context);
    }

    private static bool IsExcludedPath(string path)
    {
        foreach (var excluded in ExcludedPaths)
        {
            if (path.StartsWith(excluded, StringComparison.OrdinalIgnoreCase))
                return true;
        }

        return false;
    }
}
