import re
import os
import pandas as pd
from datetime import datetime

def clc_to_dataframe(file_path, time_unit='h'):
    """
    Reads a .clc file, extracts timestamps and variable data, and returns a DataFrame.
    
    Parameters:
    file_path (str): Path to the .clc file.
    time_unit (str): Time unit for the 'Time' column ('s' for seconds, 'm' for minutes, 'h' for hours).
    
    Returns:
    pd.DataFrame: A DataFrame with a 'Time' column and columns for each variable.
    """
    # Function to read the content of a file
    def read_file(file_path):
        with open(file_path, 'r') as file:
            return file.read()

    # Function to convert timestamps to time offsets in specified units
    def convert_timestamps(timestamps, unit='s'):
        conversion_factors = {'s': 1, 'm': 60, 'h': 3600}
        conversion_factor = conversion_factors.get(unit.lower(), 1)
        initial_time = datetime.strptime(timestamps[0], '%m-%d-%Y %H:%M:%S')
        
        # Convert timestamps to specified time unit
        converted_timestamps = [
            (datetime.strptime(timestamp, '%m-%d-%Y %H:%M:%S') - initial_time).total_seconds() / conversion_factor
            for timestamp in timestamps
        ]
        return converted_timestamps

    # Extract variable names from file content
    def extract_variable_names(file_content):
        match = re.search(r'={50,}\n(.*?)={50,}', file_content, re.DOTALL)
        if match:
            metadata = match.group(1)
            variables = re.findall(r'~~~(.*?)~~~', metadata)
            return variables
        return []

    # the general pattern for each line used to generate data and time
    def generate_pattern(n):
        base_pattern = r'(\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2})'
        variable_pattern = r',([0-9.]+),G'
        return base_pattern + (variable_pattern * n)

    # Read the file content
    data = read_file(file_path)

    # Extract variable names and number of variables
    variable_names = extract_variable_names(data)
    num_variables = len(variable_names)

    # Extract timestamped data
    pattern = generate_pattern(num_variables)
    matches = re.findall(pattern, data)

    # Parse timestamps and variable data
    timestamps = [time for time, *_ in matches]
    variables = [[float(value) for value in values] for _, *values in matches]

    # Convert timestamps to specified time units and zero offset
    t = convert_timestamps(timestamps, time_unit)

    # Convert data to DataFrame
    df = pd.DataFrame(variables, columns=variable_names)
    df.insert(0, 'Time', t)  # Insert time as the first column
    
    return df
