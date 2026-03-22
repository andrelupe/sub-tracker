using System.Security.Cryptography;
using System.Text;
using FastEndpoints;
using FastEndpoints.Swagger;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using NSwag;
using Serilog;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth;
using SubTracker.Api.Features.Auth.Services;
using SubTracker.Api.Features.ExchangeRates;
using SubTracker.Api.Features.Notifications;

// Configurar Serilog bootstrap logger
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.AspNetCore", Serilog.Events.LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "SubTracker.Api")
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/subtracker-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 7,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

try
{
    Log.Information("Starting SubTracker API");

    var builder = WebApplication.CreateBuilder(args);

    // Serilog - usar configuração do appsettings.json
    builder.Host.UseSerilog((ctx, config) =>
        config.ReadFrom.Configuration(ctx.Configuration));

    // JWT Secret Validation — ensure a valid secret exists
    var jwtSecret = builder.Configuration["Jwt:Secret"];

    if (string.IsNullOrWhiteSpace(jwtSecret) || jwtSecret == "CHANGE-THIS-TO-A-SECURE-SECRET-AT-LEAST-32-CHARS" || jwtSecret.Length < 32)
    {
        jwtSecret = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        builder.Configuration["Jwt:Secret"] = jwtSecret;
        Log.Warning("JWT secret auto-generated. Set Jwt__Secret env var for production");
    }

    // Database
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseSqlite(builder.Configuration.GetConnectionString("Default")));

    // FastEndpoints + Swagger with JWT support
    builder.Services.AddFastEndpoints();
    builder.Services.SwaggerDocument(o =>
    {
        o.DocumentSettings = s =>
        {
            s.Title = "SubTracker API";
            s.Version = "v3.0";
            s.AddAuth("Bearer", new OpenApiSecurityScheme
            {
                Type = OpenApiSecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                Description = "Enter your JWT access token"
            });
        };
    });

    // JWT Authentication
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "SubTracker",
                ValidAudience = builder.Configuration["Jwt:Audience"] ?? "SubTracker",
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]!)),
                ClockSkew = TimeSpan.Zero
            };
        });

    builder.Services.AddAuthorization();

    // Auth Services
    builder.Services.AddScoped<ITokenService, TokenService>();
    builder.Services.AddScoped<IPasswordService, PasswordService>();

    // Services
    builder.Services.AddSingleton<IDateTimeProvider, DateTimeProvider>();
    builder.Services.Configure<PushoverOptions>(builder.Configuration.GetSection("Pushover"));
    builder.Services.AddHttpClient<INotificationService, PushoverNotificationService>(client =>
        client.BaseAddress = new Uri("https://api.pushover.net/1/messages.json"));

    // Exchange Rates
    builder.Services.AddHttpClient<FrankfurterClient>(client =>
    {
        client.BaseAddress = new Uri("https://api.frankfurter.dev/v1/");
        client.Timeout = TimeSpan.FromSeconds(10);
    }).AddStandardResilienceHandler();
    builder.Services.AddSingleton<IExchangeRateService, ExchangeRateService>();

    // Background Jobs
    builder.Services.AddHostedService<CheckDueSubscriptionsJob>();
    builder.Services.AddHostedService<RefreshRatesBackgroundJob>();
    builder.Services.AddHostedService<CleanupExpiredTokensJob>();

    // CORS
    builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
        p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

    var app = builder.Build();

    // Auto-migrate, ensure admin, seed demo data
    using (var scope = app.Services.CreateScope())
    {
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync();

        var skipSeeding = app.Configuration.GetValue<bool>("SkipSeeding");

        if (!skipSeeding)
        {
            // Always ensure default admin exists and orphaned data is migrated
            await DatabaseSeeder.EnsureDefaultAdminAsync(db);

            if (app.Environment.IsDevelopment())
            {
                await DatabaseSeeder.SeedDemoDataAsync(db);
            }
        }
    }

    app.UseCors();
    app.UseAuthentication();
    app.UseAuthorization();
    app.UseSerilogRequestLogging();
    app.UseFastEndpoints();
    app.UseSwaggerGen();

    app.Run();

    Log.Information("SubTracker API stopped cleanly");
}
catch (Exception ex)
{
    Log.Fatal(ex, "SubTracker API terminated unexpectedly");

    throw;
}
finally
{
    Log.CloseAndFlush();
}

// Required for WebApplicationFactory in integration tests
public partial class Program;