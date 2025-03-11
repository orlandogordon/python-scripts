import csv
import pdfplumber
from pathlib import Path

# Directory & File path variables
tdbank_statements_path = Path('C:/Users/ogord/dev/python-scripts/budget_app/tdbank_statements')
transactions_csv_file_path = Path('C:/Users/ogord/dev/python-scripts/budget_app/transactions/tdbank_payments_output.csv')
deposits_csv_file_path = Path('C:/Users/ogord/dev/python-scripts/budget_app/deposits/tdbank_deposits_output.csv')
# Transaction data CSV headers
transaction_data = [['Date', 'Amount', 'Category', 'Description', 'Tags']]
deposit_data = [['Date', 'Description', 'Amount']]
# Used to confirm cuurent line of the PDF is a transaction (all transactions start with a date in the format MM/DD)
dates=['01/', '02/', '03/', '04/', '05/', '06/', '07/', '08/', '09/', '10/', '11/', '12/']
# Setting up lists for transaction and deposit data
transactions = []
deposits = []
# Used to manage application state. When the header of the deposits table in the PDF is discovered, 'tracking_depositis' will flip to true
# and the following lines analyzed will be added to the deposits list if they fit the expected format of a transaction entry
tracking_deposits = False
tracking_transactions = False

# Extract transaction data from bank statements
for pdf_file in tdbank_statements_path.glob('*.pdf'):
    text = ''
    with pdfplumber.open(str(pdf_file)) as pdf:
        for page in pdf.pages:
            text += page.extract_text()
    lines = text.split('\n')
    for i in range(len(lines)):
        if lines[i] == 'ElectronicPayments' or lines[i] == 'ElectronicPayments(continued)':
            tracking_transactions = True
        elif lines[i] == 'ElectronicDeposits':
            tracking_deposits =True    
        elif lines[i][0:3] in dates and (tracking_transactions or tracking_deposits):
            if lines[i+1][0:3] not in dates and not lines[i+1].startswith("Call 1-800-937-2000") and not lines[i+1].startswith("Subtotal:"):
                entry = lines[i]
                entry_split=entry.split(',')
                insert = entry_split[-1].split(' ')[0] + lines[i+1] + " " + entry_split[-1].split(' ')[-1]
                entry_split[-1] = insert
                entry = " , ".join(entry_split)
                lines[i] = entry
            if tracking_deposits: deposits.append(lines[i])
            if tracking_transactions: transactions.append(lines[i])
        elif lines[i].startswith("Call 1-800-937-2000") or lines[i].startswith("Subtotal:"):
            tracking_deposits = False
            tracking_transactions = False

# Refine transaction data and write to CSV
for transaction in transactions:
    transaction_split = transaction.split(' ')
    date = transaction_split[0]
    amount = transaction_split.pop()
    transaction_split = " ".join(transaction_split).split(',')
    description = transaction_split.pop()
    category = ''
    tags = ''
    transaction_data.append([date, amount, category, description, tags])

# Open the file in write mode
with open(transactions_csv_file_path, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerows(transaction_data)

print(f"Transaction data CSV file created at: '{transactions_csv_file_path}'.")

# Refine deposit data and write to CSV
for deposit in deposits:
    deposit_split = deposit.split(' ')
    date = deposit_split.pop(0)
    amount = deposit_split.pop()
    description = " ".join(deposit_split)
    deposit_data.append([date, description, amount])

# Open the file in write mode
with open(deposits_csv_file_path, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerows(deposit_data)

print(f"Deposit data CSV file created at: '{deposits_csv_file_path}'.")