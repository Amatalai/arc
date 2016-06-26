defmodule ArcTest.Storage.Local do
  use ExUnit.Case
  @img "test/support/image.png"
  @identifier "80d1b482-a675-4ec2-aec7-0f39631b770d"

  setup_all do
    File.mkdir_p("arctest/uploads")

    on_exit fn ->
      File.rm_rf("arctest/uploads")
    end
  end


  defmodule DummyDefinition do
    use Arc.Definition.Storage
    use Arc.Actions.Url
    @acl :public_read
    def transform(:thumb, _), do: {:convert, "-strip -thumbnail 10x10"}
    def transform(:original, _), do: :noaction
    def __versions, do: [:original, :thumb]
    def storage_dir(_, _), do: "arctest/uploads"
    def __storage, do: Arc.Storage.Local
    def identifier, do: fn-> "80d1b482-a675-4ec2-aec7-0f39631b770d" end
    def filename(:original, {file, _}) do IO.inspect(file); "original-#{file.identifier}-#{Path.basename(file.file_name, Path.extname(file.file_name))}" end
    def filename(:thumb, {file, _}), do: "1/thumb-#{file.identifier}-#{Path.basename(file.file_name, Path.extname(file.file_name))}"
  end

  test "put, delete, get" do
    assert {:ok, "original-image.png"} == Arc.Storage.Local.put(DummyDefinition, :original, {Arc.File.new(%{filename: "original-image.png", path: @img}, DummyDefinition), nil})
    assert {:ok, "1/thumb-image.png"} == Arc.Storage.Local.put(DummyDefinition, :thumb, {Arc.File.new(%{filename: "1/thumb-image.png", path: @img}, DummyDefinition), nil})

    assert File.exists?("arctest/uploads/original-image.png")
    assert File.exists?("arctest/uploads/1/thumb-image.png")
    assert "arctest/uploads/original-image.png" == DummyDefinition.url("image.png", :original)
    assert "arctest/uploads/1/thumb-image.png" == DummyDefinition.url("1/image.png", :thumb)

    Arc.Storage.Local.delete(DummyDefinition, :original, {%{file_name: "image.png"}, nil})
    Arc.Storage.Local.delete(DummyDefinition, :thumb, {%{file_name: "image.png"}, nil})
    refute File.exists?("arctest/uploads/original-#{@identifier}-image.png")
    refute File.exists?("arctest/uploads/1/thumb-#{@identifier}-image.png")
  end
end
