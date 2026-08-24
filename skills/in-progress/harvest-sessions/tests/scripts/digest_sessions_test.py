import pathlib
import runpy


def test_detects_host_invocations() -> None:
    script = pathlib.Path(__file__).parents[2] / "scripts/digest_sessions.py"
    is_harvest_session = runpy.run_path(script)["_is_harvest_session"]

    assert is_harvest_session("/harvest-sessions")
    assert is_harvest_session("Use $harvest-sessions to sweep recent sessions.")
    assert is_harvest_session(
        "<command-message>harvest-sessions</command-message>\n"
        "<command-name>/harvest-sessions</command-name>"
    )
    assert not is_harvest_session("Review the harvest-sessions implementation.")


if __name__ == "__main__":
    test_detects_host_invocations()
