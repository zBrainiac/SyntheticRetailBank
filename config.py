"""
Configuration module for Synthetic banking Data Generator - Summary Report
"""
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Optional


@dataclass
class GeneratorConfig:
    """Configuration class for the payment statement generator"""
    
    # Customer configuration
    num_customers: int = 10
    anomaly_percentage: float = 2.0  # Percentage of customers with anomalies
    
    # Time period configuration
    generation_period_months: int = 24
    start_date: Optional[datetime] = None
    
    # Transaction configuration
    avg_transactions_per_customer_per_month: float = 3.5
    
    # Currency configuration
    default_currency: str = "USD"
    available_currencies: list = None
    
    # Amount configuration
    min_transaction_amount: float = 10.0
    max_transaction_amount: float = 50000.0
    
    # Anomaly configuration
    anomaly_multiplier_min: float = 5.0  # Minimum multiplier for anomalous amounts
    anomaly_multiplier_max: float = 20.0  # Maximum multiplier for anomalous amounts
    
    # Output configuration
    output_directory: str = "generated_data"
    
    def __post_init__(self):
        """Initialize derived attributes"""
        if self.start_date is None:
            self.start_date = datetime.now() - timedelta(days=self.generation_period_months * 30)
        
        if self.available_currencies is None:
            self.available_currencies = ["USD", "EUR", "GBP", "JPY", "CAD"]
    
    @property
    def end_date(self) -> datetime:
        """Calculate the end date based on start date and period"""
        return self.start_date + timedelta(days=self.generation_period_months * 30)
    
    @property
    def num_anomalous_customers(self) -> int:
        """Calculate number of customers that should have anomalies"""
        return max(1, int(self.num_customers * self.anomaly_percentage / 100))

