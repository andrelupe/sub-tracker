using FastEndpoints;
using FastEndpoints.Swagger;
using Microsoft.EntityFrameworkCore;
using Serilog;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Notifications;

var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((ctx, config) =>
    config.ReadFrom.Configuration(ctx.Configuration));

// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("Default")));

// FastEndpoints
builder.Services.AddFastEndpoints();
builder.Services.SwaggerDocument();

// Services
builder.Services.AddSingleton<IDateTimeProvider, DateTimeProvider>();
builder.Services.Configure<PushoverOptions>(builder.Configuration.GetSection("Pushover"));
builder.Services.AddHttpClient<INotificationService, PushoverNotificationService>(client =>
    client.BaseAddress = new Uri("https://api.pushover.net/1/messages.json"));

// Background Job
builder.Services.AddHostedService<CheckDueSubscriptionsJob>();

// CORS
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();

// Auto-migrate & seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();

    if (app.Environment.IsDevelopment())
    {
        await DatabaseSeeder.SeedAsync(db);
    }
}

app.UseCors();
app.UseSerilogRequestLogging();
app.UseFastEndpoints();
app.UseSwaggerGen();

app.Run();
