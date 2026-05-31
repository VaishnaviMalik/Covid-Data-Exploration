import pandas as pd
from sqlalchemy import create_engine

# Database Connection Configuration
# you'll need to replace the "password" with your actual password for the connection
DB_URI = "mysql+pymysql://root:password@localhost:3306/covid_data_schema"
engine = create_engine(DB_URI)

def clean_and_load_csv(file_path, table_name):
    print(f"Processing {table_name}...")
    
    # Load the CSV 
    df = pd.read_csv(file_path, low_memory=False)
    
    # Standardize the Date Column to YYYY-MM-DD
    if 'date' in df.columns:
        df['date'] = pd.to_datetime(df['date'], format='%m/%d/%Y').dt.date

    # Streaming it straight into MySQL
    df.to_sql(
        name=table_name, 
        con=engine, 
        if_exists='replace', 
        index=False, 
        chunksize=10000
    )
    print(f"Successfully loaded {len(df):,} rows into '{table_name}' table!")

# Run the pipeline for both files using your Uploads directory
clean_and_load_csv(r'Datasets\CovidDeaths.csv', 'coviddeaths')
clean_and_load_csv(r'Datasets\CovidVaccinations.csv', 'covidvaccinations')