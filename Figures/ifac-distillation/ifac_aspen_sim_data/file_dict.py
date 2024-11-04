import os
import re

def extract_clc_variables(directory_path):
    """
    Extracts variable definitions from all .clc files in a specified directory.
    
    Parameters:
    - directory_path (str): The path to the directory containing .clc files.

    Returns:
    - file_variables (dict): A dictionary where each key is a filename and each value
                             is a dictionary of variables found in that file.
    """
    # Dictionary to store each file's variables
    file_variables = {}

    # Helper function to extract variables in the form a~~~X~~~
    def extract_variables(file_path):
        with open(file_path, 'r') as file:
            content = file.read()
        
        # Locate the metadata section with the variables, which is enclosed between lines of equal signs
        metadata_pattern = re.compile(r'={50,}\n(.*?)={50,}', re.DOTALL)
        metadata_match = metadata_pattern.search(content)
        
        if not metadata_match:
            print(f"No metadata found in {file_path}")
            return None

        metadata_content = metadata_match.group(1)
        
        # Dictionary to store label and variable `X` component
        variables = {}
        for line in metadata_content.strip().splitlines():
            match = re.match(r'([a-z]+)~~~(.*?)~~~', line)
            if match:
                label = match.group(1)       # Label, e.g., 'a', 'b', 'c'
                variable = match.group(2)    # X component, e.g., STREAMS("F").F
                variables[label] = variable
        
        return variables

    # Iterate over each file in the directory and extract variables
    for filename in os.listdir(directory_path):
        if filename.endswith('.clc'):
            file_path = os.path.join(directory_path, filename)
            variables = extract_variables(file_path)
            
            if variables:
                file_variables[filename] = variables
    print(file_variables)
    return file_variables
