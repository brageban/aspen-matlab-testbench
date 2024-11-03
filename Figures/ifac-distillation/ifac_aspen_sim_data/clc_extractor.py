import re
import os
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from cycler import cycler

# Directory path where .clc files are located
directory_path = r"Ratio_control"
time_unit = 'h'  # Time units (s: seconds, m: minutes, h: hours)
time_read_start = 10  # Start time in chosen unit (seconds, minutes, hours)

def export_data(file_index):
    # Function to check if directory exists and list files
    def check_directory(directory_path):
        if os.path.exists(directory_path):
            files = os.listdir(directory_path)
            print(f"Files in directory: {files}")
            return files
        else:
            print(f"Directory {directory_path} does not exist.")
            return None

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

    # Generate regex pattern to match data entries
    def generate_pattern(n):
        base_pattern = r'(\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2})'
        variable_pattern = r',([0-9.]+),G'
        return base_pattern + (variable_pattern * n)

    # Check directory and get list of files
    files = check_directory(directory_path)
    if files and 0 <= file_index < len(files):
        filex = files[file_index]
        data = read_file(os.path.join(directory_path, filex))

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

        # Plotting
        plt.figure(figsize=(10, 5))
        for var_name in variable_names:
            plt.plot(df['Time'], df[var_name], linewidth=2, label=var_name)

        plt.xlabel(f'Time ({time_unit})')
        plt.ylabel('Values')
        plt.xticks(rotation=0)
        plt.tight_layout()

        # Custom line styles
        line_cycler = (cycler(color=["red", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#F0E442"]) +
                       cycler(linestyle=["-", "-", "-.", ":", "-", "--", "-."]))
        plt.rc("axes", prop_cycle=line_cycler)

        # Grid and legend
        plt.grid(which='major', linestyle='-', linewidth='0.6', color='black', alpha=0.3)
        plt.grid(which='minor', linestyle=':', linewidth='0.6', color='black', alpha=0.3)
        plt.minorticks_on()
        plt.legend(loc='best')
        plt.show()

        # Return DataFrame for further analysis if needed
        return df
    else:
        print("File index is out of range or directory does not exist.")
        return None

# Run export_data function with a specified file index
file_index = 3
df = export_data(file_index)
print(df)
