"""
Tests para tools/sanitizer.py — DLP engine crítico del sistema.

Cubre: tokenización IPv4, credenciales, emails, hostnames, orgs,
consistencia del mapa, persistencia, init_from_scope, y casos borde.
"""

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "tools"))
from sanitizer import DLPSanitizer, _is_exempt  # noqa: E402


# ── Fixtures ─────────────────────────────────────────────────────────────────


@pytest.fixture
def eng(tmp_path):
    """Engagement dir temporal — cada test arranca con mapa vacío."""
    return DLPSanitizer(str(tmp_path))


@pytest.fixture
def eng_dir(tmp_path):
    """Retorna solo el path para tests que crean instancias manualmente."""
    return tmp_path


# ── _is_exempt ────────────────────────────────────────────────────────────────


def test_exempt_loopback():
    assert _is_exempt("127.0.0.1") is True


def test_exempt_loopback_extended():
    assert _is_exempt("127.0.0.2") is True
    assert _is_exempt("127.255.255.255") is True


def test_exempt_broadcast():
    assert _is_exempt("255.255.255.255") is True


def test_exempt_zero():
    assert _is_exempt("0.0.0.0") is True


def test_not_exempt_private():
    assert _is_exempt("192.168.1.1") is False
    assert _is_exempt("10.0.0.1") is False
    assert _is_exempt("172.16.0.1") is False


def test_not_exempt_public():
    assert _is_exempt("8.8.8.8") is False


# ── Tokenización IPv4 ─────────────────────────────────────────────────────────


def test_ip_gets_token(eng):
    result = eng.sanitize("Target: 192.168.1.50")
    assert "192.168.1.50" not in result
    assert "TGT-" in result


def test_ip_token_format(eng):
    eng.register_ip("10.10.10.5")
    token = eng._map["targets"]["10.10.10.5"]
    assert token == "TGT-001"


def test_ip_token_increments(eng):
    eng.register_ip("10.0.0.1")
    eng.register_ip("10.0.0.2")
    assert eng._map["targets"]["10.0.0.1"] == "TGT-001"
    assert eng._map["targets"]["10.0.0.2"] == "TGT-002"


def test_same_ip_same_token(eng):
    t1 = eng.register_ip("192.168.1.1")
    t2 = eng.register_ip("192.168.1.1")
    assert t1 == t2


def test_exempt_ip_not_replaced(eng):
    result = eng.sanitize("Loopback: 127.0.0.1 ok")
    assert "127.0.0.1" in result


def test_multiple_ips_in_text(eng):
    result = eng.sanitize("nmap: 10.0.0.1 10.0.0.2 10.0.0.3")
    assert "10.0.0.1" not in result
    assert "10.0.0.2" not in result
    assert "10.0.0.3" not in result
    assert result.count("TGT-") == 3


def test_same_ip_appears_twice(eng):
    result = eng.sanitize("Host 192.168.1.1 responded. Host 192.168.1.1 is up.")
    parts = result.split()
    tokens = [p.strip(".") for p in parts if p.startswith("TGT-")]
    assert len(set(tokens)) == 1, "La misma IP debe producir el mismo token"


# ── Credenciales ──────────────────────────────────────────────────────────────


def test_password_kv_redacted(eng):
    result = eng.sanitize("password=supersecret123")
    assert "supersecret123" not in result
    assert "[CREDENTIAL-REDACTED]" in result


def test_passwd_colon_redacted(eng):
    result = eng.sanitize("passwd: hunter2")
    assert "hunter2" not in result
    assert "[CREDENTIAL-REDACTED]" in result


def test_api_key_redacted(eng):
    result = eng.sanitize("api_key=AKIAIOSFODNN7EXAMPLE")
    assert "AKIAIOSFODNN7EXAMPLE" not in result
    assert "[CREDENTIAL-REDACTED]" in result


def test_unix_hash_redacted(eng):
    unix_hash = "$6$rounds=5000$salt$hashedpassword1234567890abcdefghijklmnopqrstuvwxyz"
    result = eng.sanitize(f"root:{unix_hash}:18000:0:99999:7:::")
    assert unix_hash not in result
    assert "[CREDENTIAL-REDACTED]" in result


def test_sha256_hash_redacted(eng):
    sha256 = "a" * 64
    result = eng.sanitize(f"hash: {sha256}")
    assert sha256 not in result
    assert "[CREDENTIAL-REDACTED]" in result


def test_contraseña_redacted(eng):
    result = eng.sanitize("contraseña: mipassword")
    assert "mipassword" not in result
    assert "[CREDENTIAL-REDACTED]" in result


# ── Emails ────────────────────────────────────────────────────────────────────


def test_email_gets_token(eng):
    result = eng.sanitize("Contacto: admin@victima.com")
    assert "admin@victima.com" not in result
    assert "MAIL-" in result


def test_email_token_format(eng):
    eng.register_email("user@test.com")
    token = eng._map["emails"]["user@test.com"]
    assert token == "MAIL-001"


def test_same_email_same_token(eng):
    t1 = eng.register_email("admin@target.com")
    t2 = eng.register_email("admin@target.com")
    assert t1 == t2


def test_email_case_insensitive(eng):
    t1 = eng.register_email("Admin@Target.com")
    t2 = eng.register_email("admin@target.com")
    assert t1 == t2


# ── Hostnames ─────────────────────────────────────────────────────────────────


def test_host_gets_token(eng):
    eng.register_host("victima.com")
    result = eng.sanitize("Servidor: victima.com")
    assert "victima.com" not in result
    assert "HST-" in result


def test_host_token_format(eng):
    eng.register_host("target.local")
    token = eng._map["hosts"]["target.local"]
    assert token == "HST-001"


def test_same_host_same_token(eng):
    t1 = eng.register_host("dc01.corp.local")
    t2 = eng.register_host("dc01.corp.local")
    assert t1 == t2


def test_host_trailing_dot_stripped(eng):
    t1 = eng.register_host("target.com.")
    t2 = eng.register_host("target.com")
    assert t1 == t2


def test_host_case_insensitive(eng):
    t1 = eng.register_host("Target.COM")
    t2 = eng.register_host("target.com")
    assert t1 == t2


# ── Organizaciones ────────────────────────────────────────────────────────────


def test_org_gets_token(eng):
    eng.register_org("Acme Corporation")
    result = eng.sanitize("Empresa: Acme Corporation contacto")
    assert "Acme Corporation" not in result
    assert "ORG-" in result


def test_short_org_not_registered(eng):
    token = eng.register_org("AB")
    assert token == "AB"
    assert len(eng._map["orgs"]) == 0


# ── Persistencia del mapa ─────────────────────────────────────────────────────


def test_map_persists_across_instances(eng_dir):
    s1 = DLPSanitizer(str(eng_dir))
    s1.register_ip("10.10.10.1")

    s2 = DLPSanitizer(str(eng_dir))
    assert "10.10.10.1" in s2._map["targets"]
    assert s2._map["targets"]["10.10.10.1"] == "TGT-001"


def test_counters_persist(eng_dir):
    s1 = DLPSanitizer(str(eng_dir))
    s1.register_ip("10.0.0.1")
    s1.register_ip("10.0.0.2")

    s2 = DLPSanitizer(str(eng_dir))
    token = s2.register_ip("10.0.0.3")
    assert token == "TGT-003"


def test_map_file_created(eng_dir):
    s = DLPSanitizer(str(eng_dir))
    s.register_ip("10.0.0.1")
    assert (eng_dir / "dlp-map.json").exists()


def test_map_file_valid_json(eng_dir):
    s = DLPSanitizer(str(eng_dir))
    s.register_ip("10.0.0.1")
    data = json.loads((eng_dir / "dlp-map.json").read_text())
    assert data["version"] == 2
    assert "targets" in data
    assert "counters" in data


# ── init_from_scope ───────────────────────────────────────────────────────────


def test_init_from_scope_registers_ips(eng_dir):
    scope = eng_dir / "scope.md"
    scope.write_text("Target: 192.168.10.5\nOtro: 10.0.0.100\n")

    s = DLPSanitizer(str(eng_dir))
    s.init_from_scope()

    assert "192.168.10.5" in s._map["targets"]
    assert "10.0.0.100" in s._map["targets"]


def test_init_from_scope_skips_exempt(eng_dir):
    scope = eng_dir / "scope.md"
    scope.write_text("Loopback: 127.0.0.1\nTarget: 10.0.0.1\n")

    s = DLPSanitizer(str(eng_dir))
    s.init_from_scope()

    assert "127.0.0.1" not in s._map["targets"]
    assert "10.0.0.1" in s._map["targets"]


def test_init_from_scope_registers_emails(eng_dir):
    scope = eng_dir / "scope.md"
    scope.write_text("Contacto: pentest@cliente.com\n")

    s = DLPSanitizer(str(eng_dir))
    s.init_from_scope()

    assert "pentest@cliente.com" in s._map["emails"]


def test_init_from_scope_missing_file(eng_dir, capsys):
    s = DLPSanitizer(str(eng_dir))
    s.init_from_scope()
    captured = capsys.readouterr()
    assert "no encontrado" in captured.err


# ── Casos borde ───────────────────────────────────────────────────────────────


def test_empty_string(eng):
    assert eng.sanitize("") == ""


def test_none_like_empty(eng):
    assert eng.sanitize("") == ""


def test_text_without_sensitives(eng):
    text = "Puerto 80 abierto — HTTP sin credenciales"
    result = eng.sanitize(text)
    assert result == text


def test_ip_not_in_cidr_notation_preserved(eng):
    # Una IP dentro de una notación CIDR completa igual debe tokenizarse
    result = eng.sanitize("Red: 10.0.0.0/24")
    assert "10.0.0.0" not in result


def test_ipv6_not_tokenized(eng):
    """IPv6 no está soportado aún (M1 issue: fix(dlp): add IPv6 tokenization)."""
    ipv6 = "2001:db8::1"
    result = eng.sanitize(f"Target IPv6: {ipv6}")
    assert ipv6 in result, "IPv6 no debe tokenizarse hasta que se implemente (M1)"


def test_corrupt_map_file_resets(eng_dir):
    map_file = eng_dir / "dlp-map.json"
    map_file.write_text("{ corrupt json }")

    s = DLPSanitizer(str(eng_dir))
    assert s._map["version"] == 2
    assert s._map["targets"] == {}


def test_email_before_host_no_double_replace(eng):
    """El email no debe ser fragmentado al reemplazar el host."""
    eng.register_host("victima.com")
    result = eng.sanitize("admin@victima.com")
    # El email completo debe haberse reemplazado como MAIL token
    assert "@" not in result or "MAIL-" in result
