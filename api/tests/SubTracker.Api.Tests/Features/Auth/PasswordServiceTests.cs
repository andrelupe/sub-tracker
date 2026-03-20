using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Tests.Features.Auth;

public class PasswordServiceTests
{
    private readonly PasswordService _sut = new();

    [Fact]
    public void Hash_ShouldReturnBCryptHash()
    {
        var hash = _sut.Hash("MyPassword123!");

        Assert.StartsWith("$2", hash);
    }

    [Fact]
    public void Hash_ShouldReturnDifferentHashesForSamePassword()
    {
        var hash1 = _sut.Hash("MyPassword123!");
        var hash2 = _sut.Hash("MyPassword123!");

        Assert.NotEqual(hash1, hash2);
    }

    [Fact]
    public void Verify_ShouldReturnTrue_ForCorrectPassword()
    {
        var password = "MyPassword123!";
        var hash = _sut.Hash(password);

        Assert.True(_sut.Verify(password, hash));
    }

    [Fact]
    public void Verify_ShouldReturnFalse_ForIncorrectPassword()
    {
        var hash = _sut.Hash("CorrectPassword");

        Assert.False(_sut.Verify("WrongPassword", hash));
    }
}