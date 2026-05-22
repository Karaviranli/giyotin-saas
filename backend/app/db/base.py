from app.db.database import Base 

# Modelleri buraya ekliyoruz ki Base hepsiyle birleşsin
from app.models.user import User
from app.models.company import Company
from app.models.subscription import Subscription
from app.models.giyotin import GiyotinRecord