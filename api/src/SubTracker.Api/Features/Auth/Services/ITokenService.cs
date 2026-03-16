using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Features.Auth.Services;

public interface ITokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    string HashToken(string token);
}
