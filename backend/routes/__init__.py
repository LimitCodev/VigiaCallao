from routes import alerts, auth, cameras, health


def register_blueprints(app) -> None:
    app.register_blueprint(health.bp)
    app.register_blueprint(alerts.bp)
    app.register_blueprint(cameras.bp)
    app.register_blueprint(auth.bp)
