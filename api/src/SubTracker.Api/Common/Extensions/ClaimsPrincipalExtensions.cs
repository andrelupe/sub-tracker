using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Common.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal principal)
    {
        var sub = principal.FindFirstValue(JwtRegisteredClaimNames.Sub)
                  ?? principal.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? throw new UnauthorizedAccessException("User ID claim not found");

        return Guid.Parse(sub);
    }

    public static bool IsAdmin(this ClaimsPrincipal principal)
        => principal.IsInRole(UserRole.Admin.ToString());
}