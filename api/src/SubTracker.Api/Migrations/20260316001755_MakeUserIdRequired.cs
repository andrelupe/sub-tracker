using System;
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SubTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class MakeUserIdRequired : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ── Data migration: ensure orphaned records have a valid UserId ──
            // This handles the upgrade scenario where existing Subscriptions/UserSettings
            // have NULL UserId from the previous migration (AddMultiUserSupport).
            // On a fresh DB this is a no-op (no existing data).

            var adminId = Guid.NewGuid().ToString();
            var password = GenerateSecurePassword(16);
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(password, 12);
            var utcNow = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");

            // Create default admin only if no users exist AND there are orphaned records
            migrationBuilder.Sql($"""
                INSERT INTO Users (Id, Email, PasswordHash, Role, ResetToken, ResetTokenExpiresAt, CreatedAt, UpdatedAt)
                SELECT '{adminId}', 'admin@subtracker.local', '{passwordHash}', 'Admin', NULL, NULL, '{utcNow}', '{utcNow}'
                WHERE NOT EXISTS (SELECT 1 FROM Users)
                  AND (EXISTS (SELECT 1 FROM Subscriptions WHERE UserId IS NULL)
                       OR EXISTS (SELECT 1 FROM UserSettings WHERE UserId IS NULL));
                """);

            // Assign orphaned Subscriptions to the first admin user
            migrationBuilder.Sql("""
                UPDATE Subscriptions
                SET UserId = (SELECT Id FROM Users WHERE Role = 'Admin' ORDER BY CreatedAt LIMIT 1)
                WHERE UserId IS NULL;
                """);

            // Assign orphaned UserSettings to the first admin user
            migrationBuilder.Sql("""
                UPDATE UserSettings
                SET UserId = (SELECT Id FROM Users WHERE Role = 'Admin' ORDER BY CreatedAt LIMIT 1)
                WHERE UserId IS NULL;
                """);

            // Note: On upgrade, password is logged above via Console.
            // On fresh DB, the INSERT is a no-op and the DatabaseSeeder creates the admin with Serilog logging.

            // ── Schema changes: make UserId NOT NULL and add FK constraints ──

            migrationBuilder.DropForeignKey(
                name: "FK_Subscriptions_Users_UserId",
                table: "Subscriptions");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserSettings",
                type: "TEXT",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "TEXT",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "Subscriptions",
                type: "TEXT",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "TEXT",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserSettings_UserId",
                table: "UserSettings",
                column: "UserId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Subscriptions_Users_UserId",
                table: "Subscriptions",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserSettings_Users_UserId",
                table: "UserSettings",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Subscriptions_Users_UserId",
                table: "Subscriptions");

            migrationBuilder.DropForeignKey(
                name: "FK_UserSettings_Users_UserId",
                table: "UserSettings");

            migrationBuilder.DropIndex(
                name: "IX_UserSettings_UserId",
                table: "UserSettings");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserSettings",
                type: "TEXT",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "TEXT");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "Subscriptions",
                type: "TEXT",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "TEXT");

            migrationBuilder.AddForeignKey(
                name: "FK_Subscriptions_Users_UserId",
                table: "Subscriptions",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        private static string GenerateSecurePassword(int length)
        {
            const string chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%&*";
            return RandomNumberGenerator.GetString(chars, length);
        }
    }
}
