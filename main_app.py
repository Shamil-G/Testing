from __init__ import app
import config as cfg

#
# Ни в коем случае не удалять строки ниже, иначе APP не узнает свои контексты
from view import routes
from db_oracle import UserLogin

print("Application started")


if __name__ == "__main__":
    print("Application had started __main__")
    app.run(host=cfg.host, port=cfg.port, debug=False)
