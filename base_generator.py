"""
Base generator class with common functionality for all data generators
"""
from abc import ABC, abstractmethod
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional
import csv
import logging

from config import GeneratorConfig


class BaseGenerator(ABC):
    """Base class for all data generators with common functionality"""
    
    def __init__(self, config: GeneratorConfig):
        self.config = config
        self.output_dir = Path(config.output_directory)
        self.logger = logging.getLogger(self.__class__.__name__)
    
    @staticmethod
    def get_utc_timestamp() -> str:
        """Standardized UTC timestamp format used across all generators"""
        return datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    
    def ensure_directory(self, path: Path) -> None:
        """Create directory if it doesn't exist"""
        path.mkdir(parents=True, exist_ok=True)
    
    def write_csv_safe(self, data: List[Any], filepath: Path, headers: List[str]) -> None:
        """Safe CSV writing with error handling"""
        try:
            self.ensure_directory(filepath.parent)
            with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(headers)
                for row in data:
                    if hasattr(row, '__dict__'):
                        # Handle dataclass objects
                        writer.writerow([getattr(row, field) for field in headers])
                    else:
                        # Handle dict or list objects
                        writer.writerow(row)
        except Exception as e:
            self.logger.error(f"Failed to write CSV file {filepath}: {e}")
            raise
    
    def get_headers_from_dataclass(self, dataclass_instance: Any) -> List[str]:
        """Extract headers from dataclass field names"""
        if hasattr(dataclass_instance, '__dataclass_fields__'):
            return list(dataclass_instance.__dataclass_fields__.keys())
        return []
    
    @abstractmethod
    def generate(self) -> Dict[str, Any]:
        """Generate data - must be implemented by subclasses"""
        pass
