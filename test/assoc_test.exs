defmodule AssocTest do
  use ExUnit.Case

  import Ecto.Query

  alias ExAudit.Test.{TrackerRepo, Repo, Version, BlogPost, Comment, Util, UserGroup, Avatar, User}

  setup _ do
    :erlang.system_flag(:backtrace_depth, 50)
    :ok
  end

  test "comment lifecycle tracked" do
    user = Util.create_user()

    ExAudit.track(%{actor_id: user.id})

    params = %{
      title: "Controversial post",
      author_id: user.id,
      comments: [
        %{
          body: "lorem impusdrfnia",
          author_id: user.id
        }
      ]
    }

    changeset = BlogPost.changeset(%BlogPost{}, params)
    {:ok, %{comments: [comment]}} = Repo.insert(changeset)

    [%{actor_id: actor_id}] = comment_history = Repo.history(comment)
    assert length(comment_history) == 1
    assert actor_id == user.id
  end

  test "should track cascading deletions (before they happen)" do
    user = Util.create_user()

    ExAudit.track(%{actor_id: user.id})

    params = %{
      title: "Controversial post",
      author_id: user.id,
      comments: [
        %{
          body: "lorem impusdrfnia",
          author_id: user.id
        },
        %{
          body: "That's a nice article",
          author_id: user.id
        },
        %{
          body: "We want more of this CONTENT",
          author_id: user.id
        }
      ]
    }

    changeset = BlogPost.changeset(%BlogPost{}, params)
    {:ok, %{comments: comments} = blog_post} = Repo.insert(changeset)

    Repo.delete(blog_post)

    comment_ids = Enum.map(comments, & &1.id)

    versions =
      TrackerRepo.all(
        from(v in Version,
          where: v.entity_id in ^comment_ids,
          where: v.entity_schema == ^Comment
        )
      )

    # 3 created, 3 deleted
    assert length(versions) == 6
  end

  test "should return changesets from constraint errors" do
    user = Util.create_user()

    ch = UserGroup.changeset(%UserGroup{}, %{name: "a group", user_id: user.id})
    {:ok, _group} = Repo.insert(ch)

    import Ecto.Changeset

    deletion =
      user
      |> change
      |> no_assoc_constraint(:groups)

    assert {:error, %Ecto.Changeset{}} = Repo.delete(deletion)
  end

  test "should ignore audit" do
    ExAudit.track(%{version: Ecto.UUID.generate()})
    user = Util.create_user()

    ExAudit.track(%{actor_id: user.id}, override: true)

    params = %{
      title: "Controversial post",
      author_id: user.id,
      comments: [
        %{
          body: "lorem impusdrfnia",
          author_id: user.id
        }
      ]
    }

    ExAudit.track(%{version: Ecto.UUID.generate()})

    changeset = BlogPost.changeset(%BlogPost{}, params)
    {:ok, %{comments: [comment]} = blog} = Repo.insert(changeset, ignore_audit: true)

    assert [] = Repo.history(blog)
    assert [] = Repo.history(comment)
  end

  test "applies changes to ebmedded schemas" do
    ExAudit.track(%{version: Ecto.UUID.generate()})
    user = Util.create_user()
    ExAudit.track(%{actor_id: user.id})

    attrs = %{
      avatars: [
        %{url: "http://example.com/1.jpeg"}
      ]
    }

    changeset =
      user
      |> User.changeset(attrs)

    {:ok, user} = Repo.update(changeset)

    assert [_, _] = Repo.history(user)
  end
end
