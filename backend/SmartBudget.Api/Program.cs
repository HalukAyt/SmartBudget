using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartBudget.Api.Authentication;
using SmartBudget.Api.Data;
using SmartBudget.Api.Entities;
using SmartBudget.Api.HealthChecks;
using SmartBudget.Api.Middleware;
using SmartBudget.Api.Services;
using SmartBudget.Api.Services.AI;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection must be configured via user secrets or environment variables.");
}

var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
var jwtOptions = jwtSection.Get<JwtOptions>()
    ?? throw new InvalidOperationException("JWT configuration is missing.");

if (string.IsNullOrWhiteSpace(jwtOptions.Issuer) ||
    string.IsNullOrWhiteSpace(jwtOptions.Audience) ||
    Encoding.UTF8.GetByteCount(jwtOptions.Key) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Issuer, Jwt:Audience and a signing key of at least 32 bytes must be configured via user secrets or environment variables.");
}

if (jwtOptions.ExpirationMinutes != JwtOptions.RequiredExpirationMinutes)
{
    throw new InvalidOperationException(
        $"Jwt:ExpirationMinutes must be {JwtOptions.RequiredExpirationMinutes} for the MVP.");
}

builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));
builder.Services.Configure<JwtOptions>(jwtSection);
builder.Services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();
builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<CategoryService>();
builder.Services.AddScoped<ExpenseService>();
builder.Services.AddScoped<IncomeService>();
builder.Services.AddScoped<BudgetService>();
builder.Services.AddScoped<BillService>();
builder.Services.AddScoped<DashboardService>();
builder.Services.AddScoped<RecurringRuleService>();
builder.Services.AddHostedService<RecurringRuleRealizationHostedService>();
builder.Services.Configure<AiOptions>(builder.Configuration.GetSection(AiOptions.SectionName));
builder.Services.AddHttpClient<IAiCategorizationClient, OpenAiCategorizationClient>((services, client) =>
{
    var options = services.GetRequiredService<Microsoft.Extensions.Options.IOptions<AiOptions>>().Value;
    client.Timeout = TimeSpan.FromSeconds(options.TimeoutSeconds is > 0 and <= 120
        ? options.TimeoutSeconds
        : 15);
});
builder.Services.AddHttpClient<IAiMonthlyAnalysisClient, OpenAiMonthlyAnalysisClient>((services, client) =>
{
    var options = services.GetRequiredService<Microsoft.Extensions.Options.IOptions<AiOptions>>().Value;
    client.Timeout = TimeSpan.FromSeconds(options.TimeoutSeconds is > 0 and <= 120
        ? options.TimeoutSeconds
        : 15);
});
builder.Services.AddScoped<AiCategorizationService>();
builder.Services.AddScoped<AiMonthlyAnalysisService>();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<CurrentUserAccessor>();
builder.Services.AddHealthChecks().AddCheck<DatabaseHealthCheck>("database");

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.Key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero,
            NameClaimType = ClaimTypes.NameIdentifier
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    var bearerScheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Description = "Enter the JWT access token without the 'Bearer ' prefix.",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Reference = new OpenApiReference
        {
            Type = ReferenceType.SecurityScheme,
            Id = JwtBearerDefaults.AuthenticationScheme
        }
    };

    options.AddSecurityDefinition(JwtBearerDefaults.AuthenticationScheme, bearerScheme);
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        [bearerScheme] = Array.Empty<string>()
    });
});

var app = builder.Build();

// Applies any pending EF Core migrations on startup. Idempotent — re-running
// against an already up-to-date schema is a no-op. This lets `docker compose
// up --build` produce a ready-to-use local/evaluation database without a
// separate `dotnet ef database update` step.
using (var startupScope = app.Services.CreateScope())
{
    var startupDbContext = startupScope.ServiceProvider.GetRequiredService<AppDbContext>();
    await startupDbContext.Database.MigrateAsync();
}

app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
