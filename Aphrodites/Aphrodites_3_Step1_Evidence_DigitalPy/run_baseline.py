"""Drive DigitalPy's Filmology example in-process, the way its own (skipped) test does,
and print what each step of the Aphrodites step 1 scenario does on it as it is.

Run from the DigitalPy clone root:  <venv>/bin/python <this file> <run-dir>
Nothing in the clone is edited; the SQLite store is created in <run-dir>.
"""
import json
import logging
import pathlib
import sqlite3
import sys
import traceback
from unittest import mock
from unittest.mock import MagicMock

RUN = pathlib.Path(sys.argv[1]).resolve()
RUN.mkdir(parents=True, exist_ok=True)
DB_FILE = RUN / "filmology.db"
DB_FILE.unlink(missing_ok=True)
sys.path.insert(0, str(pathlib.Path.cwd()))
logging.basicConfig(level=logging.ERROR, stream=sys.stdout, format="   LOG %(levelname)s %(name)s: %(message)s")

PC = "filmology_app.components.FilmologyManagement.controllers.FilmologyManagement_persistence_controller"
FACADE = "filmology_app.components.FilmologyManagement.FilmologyManagement_facade.FilmologyManagement"

from digitalpy.core.domain.domain.network_client import NetworkClient  # noqa: E402
from digitalpy.core.main.object_factory import ObjectFactory  # noqa: E402
from digitalpy.testing.facade_utilities import initialize_facade, initialize_test_environment  # noqa: E402

import contextlib, io  # noqa: E402

with contextlib.redirect_stdout(io.StringIO()):  # the helper prints its own progress
    initialize_test_environment()

if "--work-around-case" in sys.argv:
    # As shipped, the framework lower-cases the type name (load_configuration.py:31) while the
    # example's files are Date.json, Movie.json ...; on Linux nothing can be constructed.
    # This shim finds the file whatever its case, so that the rest can be observed.
    from digitalpy.core.parsing.load_configuration import LoadConfiguration

    class CaseShim:
        def __init__(self, template):
            self.template = template

        def substitute(self, **values):
            path = pathlib.Path(self.template.substitute(**values))
            if not path.exists() and path.parent.is_dir():
                for candidate in path.parent.iterdir():
                    if candidate.name.lower() == path.name.lower():
                        return str(candidate)
            return str(path)

    _find = LoadConfiguration.find_configuration

    def find_configuration(self, message_type):
        if not isinstance(self.configuration_path_template, CaseShim):
            self.configuration_path_template = CaseShim(self.configuration_path_template)
        return _find(self, message_type)

    LoadConfiguration.find_configuration = find_configuration
    print("NOTE: running with the file-name case work-around")

patcher = mock.patch(PC + ".DB_PATH", "sqlite:///" + str(DB_FILE))
patcher.start()


def rows(table):
    if not DB_FILE.exists():
        return "no store file"
    con = sqlite3.connect(DB_FILE)
    try:
        return con.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
    except sqlite3.Error as error:
        return f"error: {error}"
    finally:
        con.close()


def show(obj, names):
    return {n: getattr(obj, n, "<no attribute>") for n in names}


def call(label, action, body=None, show_names=("oid", "name"), **values):
    """One request. Returns the list in the response's "message", or None."""
    print(f"\n== {label}\n   action {action}  body {body}  values {values}")
    request = ObjectFactory.get_new_instance("request")
    response = ObjectFactory.get_new_instance("response")
    try:
        facade = initialize_facade(FACADE, request, response)
        # the facade logs an exception and carries on; make the logged text visible
        facade.logger.fatal = lambda text, *a, **k: print("   FACADE LOGGED FATAL:", str(text)[:300])
        request.set_value("client", MagicMock(spec=NetworkClient))
        if body is not None:
            request.set_value("body", json.dumps(body).encode())
        for key, value in values.items():
            request.set_value(key, value)
        facade.execute(action)
    except BaseException as error:  # noqa: BLE001 - we want to see every way it can end
        print(f"   RAISED {type(error).__name__}: {error}")
        traceback.print_exc(limit=2, file=sys.stdout)
        return None
    message = response.get_value("message")
    if message is None:
        print("   response has no message; other values:", {k: str(v)[:80] for k, v in response.get_values().items()})
        return None
    print(f"   message holds {len(message)} record(s)")
    for record in message[:4]:
        print("  ", show(record, show_names))
    return message


def oid(message):
    return str(message[0].oid) if message else None


# --- scenario steps, as far as the example's model allows -------------------------------
d1 = call("step 1: create a date with year 1927", "POSTDate", {"year": "1927", "name": "d1"}, ("oid", "year"))
call("step 2: create a date with year 927 (must be refused)", "POSTDate", {"year": "927", "name": "bad"}, ("oid", "year"))
print("   Date rows in the store:", rows("Date"))
call("check 4: a date whose year is a list, not text or a number", "POSTDate", {"year": [1, 2], "name": "wrong type"}, ("oid", "year"))
print("   Date rows in the store:", rows("Date"))
p1 = call("step 3: create a director", "POSTDirector", {"name": "Director One"}, ("oid", "name"))
print("   Director rows:", rows("Director"))

m1 = call("step 4: create movie 'Film One', empty color, release date D1", "POSTMovie",
          {"name": "Film One", "color": "", "Date": oid(d1)}, ("oid", "name", "color", "CompositionPosterPrimary", "Date"))
print("   Movie rows:", rows("Movie"), "| Poster rows:", rows("Poster"))
mx = call("step 5a: create movie 'Film X' with nothing but its name", "POSTMovie", {"name": "Film X"},
          ("oid", "name", "color", "CompositionPosterPrimary", "Date"))
print("   Movie rows:", rows("Movie"), "| Poster rows:", rows("Poster"), "| Date rows:", rows("Date"), "| Director rows:", rows("Director"))

got = call("read one movie by its identifier (Film One)", "GETMovieId", None, ("oid", "name"), ID=oid(m1))
call("step 14 shape: read a movie that does not exist", "GETMovieId", None, ("oid", "name"), ID="Movie:does-not-exist")

call("step 5b: delete movie 'Film X' only", "DELETEMovie", None, ("oid", "name"), ID=oid(mx))
print("   Movie rows left (1 expected, 'Film One'):", rows("Movie"))

call("identifier: create a director and give an identifier in the body", "POSTDirector",
     {"name": "Director Two", "oid": "Director:chosen-by-the-caller"}, ("oid", "name"))

call("unknown operation", "NoSuchOperation")

# --- second pass: every field the store demands is filled in ---------------------------
BASE = {"created": "2026-11-26", "creator": "tester", "last_editor": "tester", "modified": "2026-11-26T12:00:00Z",
        "description": "d"}
PERSON = dict(BASE, surname="One", birth="1900-01-01", nationality="n")
MOVIE = dict(BASE, alias="", plot="p", runtime="90", country="c", date="1927-01-01", URL="u")
MV = ("oid", "name", "color", "CompositionPosterPrimary", "Date")

p1 = call("second pass, step 3: create a director with every field", "POSTDirector", dict(PERSON, name="Director One"))
print("   Director rows:", rows("Director"))
po = call("create a poster on its own", "POSTPoster", {"name": "film-one.png"})
print("   Poster rows:", rows("Poster"))
m1 = call("second pass, step 4: movie 'Film One', empty color, date D1 (1927), poster given", "POSTMovie",
          dict(MOVIE, name="Film One", color="", Date=oid(d1), CompositionPosterPrimary=oid(po)), MV)
print("   Movie rows:", rows("Movie"), "| Poster rows:", rows("Poster"))
m2 = call("movie 'Film Two' with no poster, no release date, no director", "POSTMovie",
          dict(MOVIE, name="Film Two", color="color"), MV)
print("   Movie rows:", rows("Movie"), "| Poster rows:", rows("Poster"))
call("read ONE movie by its identifier (Film One); 1 record expected", "GETMovieId", None, ("oid", "name"), ID=oid(m1))
call("read a movie that does not exist; 'not found' expected", "GETMovieId", None, ("oid", "name"), ID="Movie:does-not-exist")
call("delete the date D1 that 'Film One' is released on; refusal expected", "DELETEDate", None, ("oid", "year"), ID=oid(d1))
print("   Date rows left (3 expected):", rows("Date"), "| Movie rows:", rows("Movie"))
call("delete ONLY 'Film Two'", "DELETEMovie", None, ("oid", "name"), ID=oid(m2))
print("   Movie rows left (1 expected):", rows("Movie"), "| Poster rows left:", rows("Poster"))

# --- check 3: the store cannot be used -------------------------------------------------
patcher.stop()
mock.patch(PC + ".DB_PATH", "sqlite:////nonexistent-directory/filmology.db").start()
call("check 3: read all dates while the store cannot be opened", "GETDate", None, ("oid", "year"))
