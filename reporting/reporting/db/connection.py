from __future__ import annotations

from contextlib import contextmanager
from typing import Any, Iterator

from reporting.runtime import get_settings


@contextmanager
def get_db_connection(autocommit: bool = False) -> Iterator[Any]:
    import certifi
    import pytds

    settings = get_settings()
    attrs = settings.sql_connection_attributes
    server = attrs.get('Server', attrs.get('Addr', '')).replace('tcp:', '')
    host, _, port_str = server.partition(',')
    trust_server_certificate = attrs.get('TrustServerCertificate', 'no').lower() == 'yes'
    encrypt = attrs.get('Encrypt', 'yes').lower() == 'yes'

    connect_kwargs: dict[str, Any] = {
        'server': host,
        'database': attrs.get('Database'),
        'user': attrs.get('Uid'),
        'password': attrs.get('Pwd'),
        'port': int(port_str) if port_str else 1433,
        'autocommit': autocommit,
        'login_timeout': int(attrs.get('Connection Timeout', '30')),
        'timeout': int(attrs.get('Connection Timeout', '30')),
        'use_mars': False,
    }
    if encrypt:
        connect_kwargs['cafile'] = certifi.where()
        connect_kwargs['validate_host'] = not trust_server_certificate

    connection = pytds.connect(**connect_kwargs)
    try:
        yield connection
    finally:
        connection.close()
