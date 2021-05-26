defmodule FollowerMazeTest.Event do
  use ExUnit.Case
  doctest FollowerMaze.Event

  alias FollowerMaze.Event

  test "parse event fails" do
    assert_raise ArgumentError, fn -> Event.parse("corrupted") end
    assert_raise ArgumentError, fn -> Event.parse("43P3256") end
    assert_raise ArgumentError, fn -> Event.parse("43 P,32/56") end
    assert_raise ArgumentError, fn -> Event.parse("|43|P|32|56|") end
    assert_raise ArgumentError, fn -> Event.parse("12345") end
    assert_raise ArgumentError, fn -> Event.parse("3|P|2|6|5") end
    assert_raise ArgumentError, fn -> Event.parse("43|Bmore") end
    assert_raise ArgumentError, fn -> Event.parse("43|Bmore") end
    assert_raise ArgumentError, fn -> Event.parse("P|32|56") end
    assert_raise ArgumentError, fn -> Event.parse("A3|P|32|56") end
    assert_raise ArgumentError, fn -> Event.parse("43|P|B2|56") end
    assert_raise ArgumentError, fn -> Event.parse("43|P|32|f6") end
    assert_raise ArgumentError, fn -> Event.parse("43||32|56") end
    assert_raise ArgumentError, fn -> Event.parse("43|T|32|56") end
    assert_raise ArgumentError, fn -> Event.parse("666|F|60") end
    assert_raise ArgumentError, fn -> Event.parse("1|U|12|") end
    assert_raise ArgumentError, fn -> Event.parse("43|P|32") end
    assert_raise ArgumentError, fn -> Event.parse("634|S|") end
  end

  test "parse event succeeds" do
    assert Event.parse("43|F|32|56") == %Event.Follow{
             seq: 43,
             from_user: 32,
             to_user: 56
           }

    assert Event.parse("43|U|32|56") == %Event.Unfollow{
             seq: 43,
             from_user: 32,
             to_user: 56
           }

    assert Event.parse("43|P|32|56") == %Event.PrivateMessage{
             seq: 43,
             from_user: 32,
             to_user: 56
           }

    assert Event.parse("43|S|32") == %Event.StatusUpdate{
             seq: 43,
             from_user: 32
           }

    assert Event.parse("43|B") == %Event.Broadcast{
             seq: 43
           }
  end
end
