using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Tests.Features.Auth;

public class TokenServiceTests
{
    private readonly TokenService _sut;
    private readonly DateTime _utcNow = new(2026, 3, 15, 12, 0, 0, DateTimeKind.Utc);

    public TokenServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Secret"] = "this-is-a-test-secret-key-that-must-be-at-least-32-chars!",
                ["Jwt:Issuer"] = "SubTracker",
                ["Jwt:Audience"] = "SubTracker",
                ["Jwt:AccessTokenExpirationMinutes"] = "15"
            })
            .Build();

        _sut = new TokenService(config);
    }

    [Fact]
    public void GenerateAccessToken_ShouldReturnValidJwt()
    {
        var user = User.Create("test@example.com", "hash", UserRole.User, _utcNow);

        var token = _sut.GenerateAccessToken(user);

        Assert.NotEmpty(token);
        var handler = new JwtSecurityTokenHandler();
        Assert.True(handler.CanReadToken(token));
    }

    [Fact]
    public void GenerateAccessToken_ShouldContainCorrectClaims()
    {
        var user = User.Create("test@example.com", "hash", UserRole.Admin, _utcNow);

        var token = _sut.GenerateAccessToken(user);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        Assert.Equal(user.Id.ToString(), jwt.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal("test@example.com", jwt.Claims.First(c => c.Type == JwtRegisteredClaimNames.Email).Value);
        Assert.Equal("Admin", jwt.Claims.First(c => c.Type == ClaimTypes.Role).Value);
        Assert.NotEmpty(jwt.Claims.First(c => c.Type == JwtRegisteredClaimNames.Jti).Value);
    }

    [Fact]
    public void GenerateAccessToken_ShouldHaveCorrectIssuerAndAudience()
    {
        var user = User.Create("test@example.com", "hash", UserRole.User, _utcNow);

        var token = _sut.GenerateAccessToken(user);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        Assert.Equal("SubTracker", jwt.Issuer);
        Assert.Contains("SubTracker", jwt.Audiences);
    }

    [Fact]
    public void GenerateAccessToken_ShouldExpireIn15Minutes()
    {
        var user = User.Create("test@example.com", "hash", UserRole.User, _utcNow);

        var token = _sut.GenerateAccessToken(user);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        var expiry = jwt.ValidTo;
        var expectedExpiry = DateTime.UtcNow.AddMinutes(15);
        Assert.True(Math.Abs((expiry - expectedExpiry).TotalSeconds) < 5);
    }

    [Fact]
    public void GenerateRefreshToken_ShouldReturnNonEmptyString()
    {
        var token = _sut.GenerateRefreshToken();

        Assert.NotEmpty(token);
    }

    [Fact]
    public void GenerateRefreshToken_ShouldReturnUniqueTokens()
    {
        var token1 = _sut.GenerateRefreshToken();
        var token2 = _sut.GenerateRefreshToken();

        Assert.NotEqual(token1, token2);
    }

    [Fact]
    public void HashToken_ShouldReturnConsistentHash()
    {
        var token = "test-token-value";

        var hash1 = _sut.HashToken(token);
        var hash2 = _sut.HashToken(token);

        Assert.Equal(hash1, hash2);
    }

    [Fact]
    public void HashToken_ShouldReturnDifferentHashForDifferentTokens()
    {
        var hash1 = _sut.HashToken("token-1");
        var hash2 = _sut.HashToken("token-2");

        Assert.NotEqual(hash1, hash2);
    }

    [Fact]
    public void HashToken_ShouldReturnBase64String()
    {
        var hash = _sut.HashToken("test-token");

        var bytes = Convert.FromBase64String(hash);
        Assert.Equal(32, bytes.Length); // SHA256 = 32 bytes
    }
}