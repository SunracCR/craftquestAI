namespace CraftQuest.Domain.Entities;

public class ClassMember
{
    public Guid ClassMemberId { get; set; }
    public Guid ClassId { get; set; }
    public Guid UserId { get; set; }
    public string MemberRole { get; set; } = "student";
    public string Status { get; set; } = "active";
    public DateTime JoinedAt { get; set; }

    public TeacherClass Class { get; set; } = null!;
    public User User { get; set; } = null!;
}
