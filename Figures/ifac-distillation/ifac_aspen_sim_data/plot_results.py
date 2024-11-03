import os
import re
import matplotlib.pyplot as plt
import pandas as pd
from itertools import cycle
from file_dict import file_variables  # Imports the dictionary of file variables
from parse_clc import clc_to_dataframe  # Imports the function to parse .clc files to DataFrame

# Directory where .clc files are located
directory_path = r"Ratio_control"

def plot_clc_files(handles, directory_path):
    # Check if handles are provided
    if not handles:
        print("No handles provided.")
        return

    # Prepare line styles to cycle through for different handles
    linestyles = cycle(['-', '--', '-.', ':'])

    # Filter files in file_variables for each handle and group by handle
    files_by_handle = {handle: [] for handle in handles}
    for handle in handles:
        matched_files = [file for file in file_variables if file.startswith(handle)]
        if matched_files:
            files_by_handle[handle] = matched_files
        else:
            print(f"No files found with handle '{handle}'.")

    # Get the maximum number of files for any handle to determine the number of subplots
    max_files = max(len(files) for files in files_by_handle.values() if files)
    if max_files == 0:
        print("No matching files found for any handle.")
        return

    # Create subplots with a common x-axis
    fig, axes = plt.subplots(max_files, 1, figsize=(10, 5 * max_files), sharex=True)
    if max_files == 1:
        axes = [axes]  # Ensure axes is a list if there's only one subplot

    # Loop over each handle and overlay its data on the subplots
    for handle, linestyle in zip(handles, linestyles):
        matched_files = files_by_handle[handle]
        
        # Plot data for each file with the current handle and linestyle
        for i, file_name in enumerate(matched_files):
            # Construct the file path
            file_path = os.path.join(directory_path, file_name)
            
            # Extract data from the file using parse_clc
            df = clc_to_dataframe(file_path)
            
            # Plot each variable in the file on the appropriate subplot
            ax = axes[i]
            for column in df.columns[1:]:  # Skip the 'Time' column
                ax.plot(df['Time'], df[column], label=f"{file_name} - {column}", linestyle=linestyle)
            
            # Set the title and y-axis label for each subplot
            ax.set_title(file_name)
            ax.set_ylabel('Value')
            ax.grid(True)

    # Set x-axis label only on the bottom subplot
    axes[-1].set_xlabel('Time (h)')
    
    # Add a legend to each subplot to differentiate handles and variables
    for ax in axes:
        ax.legend(loc='best')

    # Adjust layout and show the plot
    plt.tight_layout()
    plt.show()

# Usage: Plot files with the specified handles
handles = ["B1","B4"]
plot_clc_files(handles, directory_path)
