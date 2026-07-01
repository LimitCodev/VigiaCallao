"""Instancias compartidas entre módulos (evita imports circulares).

Se declaran vacías aquí y se inicializan con init_app() dentro de
app.py, siguiendo el patrón estándar de factory de Flask.
"""
from flask_socketio import SocketIO

socketio = SocketIO()
