"""
File generation module for daily transaction files and customer data
"""
import os
import random
from datetime import datetime, timedelta
from typing import List
from pathlib import Path

from config import GeneratorConfig
from customer_generator import CustomerGenerator
from pay_transaction_generator import TransactionGenerator
from fx_generator import FXRateGenerator, AccountGenerator
from equity_generator import EquityTradeGenerator


class FileGenerator:
    """Manages the generation of all output files"""
    
    def __init__(self, config: GeneratorConfig):
        self.config = config
        self.output_dir = Path(config.output_directory)
        
        # Define subdirectories
        self.master_data_dir = self.output_dir / "master_data"
        self.payment_transactions_dir = self.output_dir / "payment_transactions"
        self.equity_trades_dir = self.output_dir / "equity_trades"
        self.fx_rates_dir = self.output_dir / "fx_rates"
        self.reports_dir = self.output_dir / "reports"
    
    def _create_directory_structure(self):
        """Create organized directory structure for different data types"""
        directories = [
            self.output_dir,
            self.master_data_dir,
            self.payment_transactions_dir,
            self.equity_trades_dir,
            self.fx_rates_dir,
            self.reports_dir
        ]
        
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
        
        print(f"📁 Created directory structure:")
        print(f"   • {self.master_data_dir.name}/ - Customer and account master data")
        print(f"   • {self.payment_transactions_dir.name}/ - Daily payment transaction files")
        print(f"   • {self.equity_trades_dir.name}/ - Daily equity trade files")
        print(f"   • {self.fx_rates_dir.name}/ - Foreign exchange rate data")
        print(f"   • {self.reports_dir.name}/ - Summary reports and documentation")
        print()
        
    def generate_all_files(self) -> dict:
        """Generate all customer and transaction files"""
        # Create output directory structure
        self._create_directory_structure()
        
        print(f"Generating files in directory: {self.output_dir.absolute()}")
        print(f"Configuration: {self.config.num_customers} customers, {self.config.anomaly_percentage}% anomalous")
        print(f"Period: {self.config.start_date.strftime('%Y-%m-%d')} to {self.config.end_date.strftime('%Y-%m-%d')}")
        
        # Generate customers and addresses
        print("\nGenerating customer data...")
        customer_generator = CustomerGenerator(self.config)
        customers, customer_addresses = customer_generator.generate_customers()
        
        # Save customer master data
        customer_file = self.master_data_dir / "customers.csv"
        customer_generator.save_customers_to_csv(str(customer_file))
        
        # Save customer address data (SCD Type 2)
        address_file = self.master_data_dir / "customer_addresses.csv"
        customer_generator.save_addresses_to_csv(str(address_file))
        
        anomalous_customers = customer_generator.get_anomalous_customers()
        print(f"Generated {len(customers)} customers ({len(anomalous_customers)} anomalous)")
        print(f"Customer data saved to: {customer_file}")
        print(f"Address data (with insert timestamps) saved to: {address_file}")
        print(f"Total address records: {len(customer_addresses)} (append-only base table)")
        
        # Generate accounts
        print("\nGenerating account master data...")
        account_generator = AccountGenerator(self.config)
        accounts = account_generator.generate_accounts(customers)
        account_file = account_generator.save_accounts_to_csv(accounts, str(self.master_data_dir))
        print(f"Generated {len(accounts)} accounts")
        print(f"Account data saved to: {account_file}")
        
        # Generate FX rates
        print("\nGenerating FX rates...")
        fx_generator = FXRateGenerator(self.config)
        fx_rates = fx_generator.generate_fx_rates()
        files_created = fx_generator.save_fx_rates_to_csv_by_date(fx_rates, str(self.fx_rates_dir))
        print(f"Generated {len(fx_rates)} FX rate records")
        print(f"FX rates saved to: {self.fx_rates_dir} ({len(files_created)} files, one per date)")
        
        # Generate transactions
        print("\nGenerating transaction data...")
        accounts_file = f"{self.output_dir}/master_data/accounts.csv"
        transaction_generator = TransactionGenerator(self.config, customers, fx_rates, accounts_file)
        all_transactions = transaction_generator.generate_all_transactions()
        
        print(f"Generated {len(all_transactions)} total transactions")
        
        # Generate daily files
        print("\nGenerating daily transaction files...")
        daily_files = []
        current_date = self.config.start_date
        transaction_count = 0
        
        while current_date <= self.config.end_date:
            daily_transactions = transaction_generator.get_transactions_for_date(current_date)
            
            if daily_transactions:
                filename = transaction_generator.save_daily_transactions_to_csv(
                    current_date, str(self.payment_transactions_dir)
                )
                if filename:
                    daily_files.append(filename)
                    transaction_count += len(daily_transactions)
                    print(f"  {current_date.strftime('%Y-%m-%d')}: {len(daily_transactions)} transactions")
            
            current_date += timedelta(days=1)
        
        print(f"\nGenerated {len(daily_files)} daily files with {transaction_count} transactions")
        
        # Filter investment accounts for equity trading
        print("\nFiltering investment accounts for equity trading...")
        
        # Get all INVESTMENT accounts from the generated accounts
        investment_accounts = [acc for acc in accounts if acc.account_type == 'INVESTMENT']
        
        # Get customers who have investment accounts (these will be our trading customers)
        trading_customer_ids = set(acc.customer_id for acc in investment_accounts)
        trading_customers = [cust for cust in customers if cust.customer_id in trading_customer_ids]
        
        print(f"Found {len(investment_accounts)} investment accounts for {len(trading_customers)} trading customers")
        
        # Generate equity trades
        print("\nGenerating equity trade data...")
        
        # Convert fx_rates list to dict for equity generator
        # Use the latest rate for each currency pair (CHF as base)
        fx_rates_dict = {}
        for fx_rate in fx_rates:
            if fx_rate.to_currency == "CHF":  # We want rates to CHF as base currency
                fx_rates_dict[fx_rate.from_currency] = fx_rate.rate
            elif fx_rate.from_currency == "CHF":  # Inverse rate if CHF is from currency
                fx_rates_dict[fx_rate.to_currency] = 1.0 / fx_rate.rate
        
        # Ensure CHF has rate 1.0
        fx_rates_dict["CHF"] = 1.0
        
        equity_generator = EquityTradeGenerator(trading_customers, investment_accounts, fx_rates_dict)
        equity_summary = equity_generator.generate_period_data(
            self.config.start_date, 
            self.config.end_date, 
            self.equity_trades_dir
        )
        print(f"Generated {equity_summary['total_trades']} equity trades over {equity_summary['trading_days']} trading days")
        print(f"Trading customers: {equity_summary['trading_customers']} (60% of total)")
        print(f"High-volume traders: {equity_summary['high_volume_traders']} (10% of trading customers)")
        print(f"Base currency: {equity_summary['base_currency']}")
        print(f"Markets: {', '.join(equity_summary['markets'])}")
        
        # DDL generation removed - managed manually in structure/ directory
        # Legacy SQL files removed - using new structure/ directory approach
        
        # Generate summary report
        summary_file = self._generate_summary_report(
            customers, anomalous_customers, all_transactions, daily_files, accounts, fx_rates, equity_summary
        )
        
        return {
            "customer_file": str(customer_file),
            "address_file": str(address_file),
            "account_file": account_file,
            "fx_files": files_created,
            "fx_file_count": len(files_created),
            "daily_files": daily_files,
            "summary_file": summary_file,
            "total_customers": len(customers),
            "total_accounts": len(accounts),
            "anomalous_customers": len(anomalous_customers),
            "total_transactions": len(all_transactions),
            "total_fx_rates": len(fx_rates),
            "daily_file_count": len(daily_files)
        }
    
    def _generate_summary_report(self, customers: List, anomalous_customers: List, 
                               transactions: List, daily_files: List[str], accounts: List, fx_rates: List,
                               equity_summary: dict) -> str:
        """Generate a summary report of the generated data"""
        summary_file = self.reports_dir / "generation_summary.txt"
        
        # Calculate statistics
        total_amount = sum(t.amount for t in transactions)
        total_base_amount = sum(t.base_amount for t in transactions)
        avg_transaction_amount = total_amount / len(transactions) if transactions else 0
        avg_base_amount = total_base_amount / len(transactions) if transactions else 0
        
        # Count transactions by direction (based on amount sign)
        incoming_count = len([t for t in transactions if t.amount > 0])
        outgoing_count = len([t for t in transactions if t.amount < 0])
        
        # Count accounts by type and currency
        account_types = {}
        account_currencies = {}
        for account in accounts:
            account_types[account.account_type] = account_types.get(account.account_type, 0) + 1
            account_currencies[account.base_currency] = account_currencies.get(account.base_currency, 0) + 1
        
        # Count anomalous transactions (those with anomaly markers in description)
        anomalous_transactions = [
            t for t in transactions 
            if any(marker in t.description for marker in [
                "[LARGE_TRANSFER]", "[SUSPICIOUS_COUNTERPARTY]", "[ROUND_AMOUNT]",
                "[OFF_HOURS]", "[NEW_LARGE_BENEFICIARY]"
            ])
        ]
        
        with open(summary_file, 'w', encoding='utf-8') as f:
            f.write("Synthetic banking Data Generator - Summary Report\n")
            f.write("=" * 60 + "\n\n")
            
            f.write(f"Generation Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Period: {self.config.start_date.strftime('%Y-%m-%d')} to {self.config.end_date.strftime('%Y-%m-%d')}\n\n")
            
            f.write("CONFIGURATION:\n")
            f.write(f"  Number of customers: {self.config.num_customers}\n")
            f.write(f"  Anomaly percentage: {self.config.anomaly_percentage}%\n")
            f.write(f"  Generation period: {self.config.generation_period_months} months\n")
            f.write(f"  Avg transactions per customer per month: {self.config.avg_transactions_per_customer_per_month}\n\n")
            
            f.write("GENERATED DATA SUMMARY:\n")
            f.write(f"  Total customers: {len(customers)}\n")
            f.write(f"  Total accounts: {len(accounts)}\n")
            f.write(f"  Anomalous customers: {len(anomalous_customers)} ({len(anomalous_customers)/len(customers)*100:.1f}%)\n")
            f.write(f"  Total transactions: {len(transactions)}\n")
            f.write(f"  Anomalous transactions: {len(anomalous_transactions)} ({len(anomalous_transactions)/len(transactions)*100:.1f}%)\n")
            f.write(f"  FX rate records: {len(fx_rates)}\n")
            f.write(f"  Daily files generated: {len(daily_files)}\n\n")
            
            f.write("ACCOUNT DISTRIBUTION:\n")
            for acc_type, count in account_types.items():
                f.write(f"  {acc_type}: {count} accounts\n")
            f.write("\n")
            
            f.write("CURRENCY DISTRIBUTION:\n")
            for currency, count in account_currencies.items():
                f.write(f"  {currency}: {count} accounts\n")
            f.write("\n")
            
            f.write("TRANSACTION STATISTICS:\n")
            f.write(f"  Total transaction amount: ${total_amount:,.2f} (mixed currencies)\n")
            f.write(f"  Total base amount (USD): ${total_base_amount:,.2f}\n")
            f.write(f"  Average transaction amount: ${avg_transaction_amount:,.2f}\n")
            f.write(f"  Average base amount (USD): ${avg_base_amount:,.2f}\n")
            f.write(f"  Incoming transactions: {incoming_count} ({incoming_count/len(transactions)*100:.1f}%)\n")
            f.write(f"  Outgoing transactions: {outgoing_count} ({outgoing_count/len(transactions)*100:.1f}%)\n\n")
            
            f.write("EQUITY TRADE STATISTICS:\n")
            f.write(f"  Total equity trades: {equity_summary['total_trades']}\n")
            f.write(f"  Trading days: {equity_summary['trading_days']}\n")
            f.write(f"  Trading customers: {equity_summary['trading_customers']} (60% of total)\n")
            f.write(f"  High-volume traders: {equity_summary['high_volume_traders']} (10% of trading customers)\n")
            f.write(f"  Base currency: {equity_summary['base_currency']}\n")
            f.write(f"  Markets covered: {', '.join(equity_summary['markets'])}\n\n")
            
            f.write("ANOMALOUS CUSTOMERS:\n")
            for customer in anomalous_customers:
                f.write(f"  {customer.customer_id}: {customer.first_name} {customer.family_name}\n")
            
            f.write("\nFILES GENERATED:\n")
            f.write(f"📁 Master Data (master_data/):\n")
            f.write(f"  customers.csv\n")
            f.write(f"  accounts.csv\n")
            
            f.write(f"\n📁 FX Rates (fx_rates/):\n")
            f.write(f"  fx_rates.csv\n")
            
            f.write(f"\n📁 Payment Transactions (payment_transactions/):\n")
            for daily_file in daily_files:
                filename = os.path.basename(daily_file)
                f.write(f"  {filename}\n")
            
            f.write(f"\n📁 Equity Trades (equity_trades/):\n")
            # List equity trade files
            for trade_file in self.equity_trades_dir.glob("trades_*.csv"):
                f.write(f"  {trade_file.name}\n")
            
            f.write(f"\n📁 Reports (reports/):\n")
            f.write(f"  generation_summary.txt\n")
            
            f.write(f"\n📁 Database Setup:\n")
            f.write(f"  Database schema definitions are managed in the structure/ directory\n")
            f.write(f"  See structure/README_DEPLOYMENT.md for deployment instructions\n")
        
        print(f"Summary report saved to: {summary_file}")
        return str(summary_file)
    
    def clean_output_directory(self) -> None:
        """Clean the output directory of previously generated files (selective cleaning)"""
        if self.output_dir.exists():
            # Clean main directory files
            for file in self.output_dir.glob("*.csv"):
                file.unlink()
            for file in self.output_dir.glob("*.txt"):
                file.unlink()
            
            # Clean specific subdirectories that should be regenerated
            subdirs_to_clean = [
                "master_data",
                "payment_transactions", 
                "equity_trades",
                "fx_rates",
                "swift_messages",
                "emails",
                "mortgage_emails",
                "pep_data",
                "reports"
            ]
            
            for subdir_name in subdirs_to_clean:
                subdir = self.output_dir / subdir_name
                if subdir.exists():
                    for file in subdir.glob("*.csv"):
                        file.unlink()
                    for file in subdir.glob("*.txt"):
                        file.unlink()
                    for file in subdir.glob("*.xml"):
                        file.unlink()
                    for file in subdir.glob("*.json"):
                        file.unlink()
                    print(f"Cleaned subdirectory: {subdir}")
            
            print(f"Cleaned output directory: {self.output_dir}")
        else:
            print(f"Output directory doesn't exist: {self.output_dir}")
