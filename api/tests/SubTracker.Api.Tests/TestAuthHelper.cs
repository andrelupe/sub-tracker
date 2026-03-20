using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace SubTracker.Api.Tests;

public static class TestAuthHelper
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public static async Task<AuthResult> RegisterAndLogin(
        HttpClient client,
        string email = "test@test.com",
        string password = "TestPassword123!")
    {
        var payload = new StringContent(
            JsonSerializer.Serialize(new { email, password }),
            Encoding.UTF8,
            "application/json");

        var response = await client.PostAsync("/api/auth/register", payload);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        var auth = JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;

        return new AuthResult(auth.AccessToken, auth.User.Id.ToString(), auth.User.Email, auth.User.Role);
    }

    public static async Task<AuthResult> RegisterWithInviteCode(
        HttpClient client,
        string inviteCode,
        string email = "user@test.com",
        string password = "TestPassword123!")
    {
        var payload = new StringContent(
            JsonSerializer.Serialize(new { email, password, inviteCode }),
            Encoding.UTF8,
            "application/json");

        var response = await client.PostAsync("/api/auth/register", payload);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        var auth = JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;

        return new AuthResult(auth.AccessToken, auth.User.Id.ToString(), auth.User.Email, auth.User.Role);
    }

    public static void SetAuthHeader(HttpClient client, string accessToken)
    {
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    }

    public sealed record AuthResult(string AccessToken, string UserId, string Email, string Role);

    private sealed record AuthResponseDto(string AccessToken, string RefreshToken, int ExpiresIn, UserResponseDto User);
    private sealed record UserResponseDto(Guid Id, string Email, string Role);
}
