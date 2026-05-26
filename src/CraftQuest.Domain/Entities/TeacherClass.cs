namespace CraftQuest.Domain.Entities;

public class TeacherClass
{
    public Guid ClassId { get; set; }
    public Guid TeacherUserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; }

    public User TeacherUser { get; set; } = null!;
    public ICollection<ClassMember> Members { get; set; } = [];
}
