namespace CraftQuest.Domain.Entities;

public class CreditLedgerEntry
{
    public Guid CreditLedgerId { get; set; }
    public Guid UserId { get; set; }
    public string CreditType { get; set; } = string.Empty;
    public int Delta { get; set; }
    public int? BalanceAfter { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? ReferenceType { get; set; }
    public Guid? ReferenceId { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
