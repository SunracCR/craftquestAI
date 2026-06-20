using CraftQuest.Infrastructure.StudyMaterials;

namespace CraftQuest.UnitTests.StudyMaterials;

public class StudyMaterialStreamHelperTests
{
    [Fact]
    public async Task OpenSeekableCopyAsync_WhenStreamIsNotSeekable_ReturnsBufferedCopy()
    {
        var payload = "sample-pdf-bytes"u8.ToArray();
        await using var inner = new MemoryStream(payload);
        await using var nonSeekable = new NonSeekableStreamWrapper(inner);

        await using var copy = await StudyMaterialStreamHelper.OpenSeekableCopyAsync(nonSeekable);

        Assert.True(copy.CanSeek);
        Assert.Equal(0, copy.Position);
        Assert.Equal(payload.Length, copy.Length);
    }

    [Fact]
    public async Task OpenSeekableCopyAsync_WhenStreamIsSeekable_RewindsSameInstance()
    {
        var payload = "rewind-me"u8.ToArray();
        await using var stream = new MemoryStream(payload);
        stream.Position = payload.Length;

        var result = await StudyMaterialStreamHelper.OpenSeekableCopyAsync(stream);

        Assert.Same(stream, result);
        Assert.Equal(0, stream.Position);
    }

    private sealed class NonSeekableStreamWrapper : Stream
    {
        private readonly Stream _inner;

        public NonSeekableStreamWrapper(Stream inner) => _inner = inner;

        public override bool CanRead => _inner.CanRead;
        public override bool CanSeek => false;
        public override bool CanWrite => false;
        public override long Length => throw new NotSupportedException();
        public override long Position
        {
            get => throw new NotSupportedException();
            set => throw new NotSupportedException();
        }

        public override void Flush() => _inner.Flush();

        public override int Read(byte[] buffer, int offset, int count) =>
            _inner.Read(buffer, offset, count);

        public override long Seek(long offset, SeekOrigin origin) =>
            throw new NotSupportedException();

        public override void SetLength(long value) => throw new NotSupportedException();

        public override void Write(byte[] buffer, int offset, int count) =>
            throw new NotSupportedException();
    }
}
