using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Features.Auth.Services;

public sealed class TokenService : ITokenService
{
    private readonly IConfiguration _config;

    public TokenService(IConfiguration config) => _config = config;

    public string GenerateAccessToken(User user)
    {
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Secret"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var expireMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "15");

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"] ?? "SubTracker",
            audience: _config["Jwt:Audience"] ?? "SubTracker",
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expireMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken() => Guid.NewGuid().ToString("N");

    public string HashToken(string token)
        => Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
}
