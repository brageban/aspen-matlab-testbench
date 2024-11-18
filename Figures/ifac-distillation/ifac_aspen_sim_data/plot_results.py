import os
import re
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from itertools import cycle
from file_dict import extract_clc_variables  # Import the function to extract variables
from parse_clc import clc_to_dataframe  # Imports the function to parse .clc files to DataFrame

def format_label(label):
    replacements = {
        r'STREAMS\("F"\)\.F': 'F',
        r'STREAMS\("B"\)\.Zn\("WATER"\)': 'x_B_water',
        r'STREAMS\("D"\)\.Zn\("METHANOL"\)': 'x_D_methanol',
        r'VF\.Output_': 'V/F',
        r'LF\.Output_': 'L/F',
        r'BLOCKS\("COLUMN"\)\.Stage\((\d+)\)\.T': r'T_S_\1',
        r'BLOCKS\("COLUMN"\)\.FvReb': 'V',
        r'BLOCKS\("COLUMN"\)\.Reflux\.F': 'L',
        r'MIN_F\.Input_\(1\)': 'FC_F',
        r'MIN_F\.Input_\(2\)': 'LCH_D',
        r'MIN_F\.Input_\(3\)': 'LCH_B',
        r'MIN_F\.Input_\(4\)': 'CCH_B',
        r'MIN_QReb\.Input_\(1\)': 'CCL_B (QReb)',
        r'MIN_QReb\.Input_\(2\)': 'PCH_CondP',
        r'MIN_QReb\.Input_\(3\)': 'QReb_MAX',
        r'PV': 'y',
        r'OP': 'u',
        r'SP': 'Setpoint'
    }

    for pattern, replacement in replacements.items():
        if re.search(pattern, label):
            label = re.sub(pattern, replacement, label)
            break

    return label

def format_title(file_name):
    base_name = os.path.splitext(file_name)[0]
    parts = base_name.split('_')
    if len(parts) == 2:
        handle, param = parts
        return f"{handle.capitalize()} {param}"
    return file_name

def plot_clc_files(handles, directory_path):
    file_variables = extract_clc_variables(directory_path)

    if not handles:
        print("No handles provided.")
        return

    linestyles = cycle(['-', '--', '-.', ':'])

    # Updated to handle specific handle matching
    files_by_handle = {}
    for handle in handles:
        matched_files = [file for file in file_variables if file.startswith(handle + "_")]
        if matched_files:
            files_by_handle[handle] = matched_files
        else:
            print(f"No files found with handle '{handle}'.")

    # Handle scenario when no files are matched at all
    if not any(files_by_handle.values()):
        print("No matching files found for any handle.")
        return

    # Only consider non-empty file lists for calculating max_files
    max_files = max((len(files) for files in files_by_handle.values() if files), default=0)
    if max_files == 0:
        print("No matching files found for any handle.")
        return

    fig, axes = plt.subplots(max_files, 1, figsize=(7, 2 * max_files), sharex=True)
    if max_files == 1:
        axes = [axes]

    for handle, linestyle in zip(handles, linestyles):
        matched_files = files_by_handle.get(handle, [])
        
        for i, file_name in enumerate(matched_files):
            file_path = os.path.join(directory_path, file_name)
            df = clc_to_dataframe(file_path)
            
            ax = axes[i]
            secondary_ax_created = False

            for column in df.columns[1:]:
                formatted_label = format_label(column)
                
                if formatted_label == "u":
                    if not secondary_ax_created:
                        secax = ax.twinx()
                        secax.set_ylabel("u", fontsize=12)
                        secondary_ax_created = True

                    secax.plot(df['Time'], df[column], label=formatted_label, linestyle=linestyle, color="purple")
                else:
                    if "purities" in file_name.lower():
                        transformed_data = - np.log10(1 - df[column])
                        ax.plot(df['Time'], transformed_data, label=formatted_label, linestyle=linestyle)
                        
                        secax_purity = ax.secondary_yaxis('right')
                        secax_purity.set_ylabel('Purity (decimal fraction)')
                        secax_purity.set_yticks([- np.log10(1-p) for p in [0.9, 0.99, 0.999, 0.9999]])
                        secax_purity.set_yticklabels(['0.9', '0.99', '0.999', '0.9999'])
                        
                        ax.set_ylim(1, 4)
                    else:
                        ax.plot(df['Time'], df[column], label=formatted_label, linestyle=linestyle)
            
            if "temperature" in file_name.lower():
                ax.set_ylabel('Temperature (°C)', fontsize=12)
            elif "qreb" in file_name.lower():
                ax.set_ylabel('Gcal/hr')
            elif any(var.endswith(").T") for var in df.columns[1:]):
                ax.set_ylabel('Temperature (°C)', fontsize=12)
            elif "flows" in file_name.lower():
                ax.set_ylabel('kmol/hr', fontsize=12)
            elif "purities" in file_name.lower():
                ax.set_ylabel('- log(1 - Purity)', fontsize=12)
            else:
                ax.set_ylabel('Value', fontsize=12)

            ax.set_title(format_title(file_name), fontsize=12)
            ax.grid(True)

    axes[-1].set_xlabel('Time (h)', fontsize=12)
    
    for ax in axes:
        ax.legend(loc='best', fontsize=10)

    plt.tight_layout(pad=1.0)
    plt.show()

# Directory where .clc files are located
directory_path = r"Bidir_control"

# Usage: Plot files with the specified handles
handles = ["BIDIR2_1"]
plot_clc_files(handles, directory_path)
