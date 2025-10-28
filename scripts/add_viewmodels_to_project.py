#!/usr/bin/env python3
"""
Add 7 new Weight ViewModels to Xcode project.pbxproj
Phase 8.9 Phase 2 - Task 1 Integration
"""
import re
import uuid

# Generate unique IDs for Xcode references
def generate_xcode_id():
    """Generate 24-character hex ID for Xcode references"""
    return uuid.uuid4().hex.upper()[:24]

# Files to add
NEW_FILES = [
    "BadgesViewModel.swift",
    "CardsViewModel.swift",
    "GoalsViewModel.swift",
    "NotificationsViewModel.swift",
    "PreferencesViewModel.swift",
    "SyncViewModel.swift",
    "WeightControlCenterCoordinator.swift"
]

# Read project file
PROJECT_PATH = "/Users/richmarin/Desktop/FastingTracker/FastingTracker.xcodeproj/project.pbxproj"

with open(PROJECT_PATH, 'r') as f:
    content = f.read()

# Step 1: Find the Weight folder group (or ViewModels group)
# We need to add files to the correct group in the file hierarchy

# Generate file references
file_refs = {}
build_file_refs = {}

for filename in NEW_FILES:
    file_id = generate_xcode_id()
    build_file_id = generate_xcode_id()
    file_refs[filename] = file_id
    build_file_refs[filename] = build_file_id
    print(f"Generated IDs for {filename}:")
    print(f"  File Ref: {file_id}")
    print(f"  Build Ref: {build_file_id}")

# Step 2: Add PBXFileReference entries
# Find the PBXFileReference section
pbx_file_ref_section_match = re.search(r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)', content, re.DOTALL)

if pbx_file_ref_section_match:
    pbx_file_ref_section = pbx_file_ref_section_match.group(1)

    # Create new file references
    new_file_refs = ""
    for filename in NEW_FILES:
        file_id = file_refs[filename]
        new_file_refs += f'\t\t{file_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};\n'

    # Insert before "/* End PBXFileReference section */"
    updated_section = pbx_file_ref_section.replace(
        "/* End PBXFileReference section */",
        new_file_refs + "\t/* End PBXFileReference section */"
    )

    content = content.replace(pbx_file_ref_section, updated_section)
    print("\n✅ Added PBXFileReference entries")

# Step 3: Add PBXBuildFile entries
pbx_build_file_section_match = re.search(r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)', content, re.DOTALL)

if pbx_build_file_section_match:
    pbx_build_file_section = pbx_build_file_section_match.group(1)

    # Create new build file references
    new_build_refs = ""
    for filename in NEW_FILES:
        build_file_id = build_file_refs[filename]
        file_id = file_refs[filename]
        new_build_refs += f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {filename} */; }};\n'

    # Insert before "/* End PBXBuildFile section */"
    updated_section = pbx_build_file_section.replace(
        "/* End PBXBuildFile section */",
        new_build_refs + "\t/* End PBXBuildFile section */"
    )

    content = content.replace(pbx_build_file_section, updated_section)
    print("✅ Added PBXBuildFile entries")

# Step 4: Find ViewModels group and add files
# Look for the ViewModels group
viewmodels_group_match = re.search(r'([A-F0-9]{24}) /\* ViewModels \*/ = \{[^}]+children = \(\s*([^)]+)\s*\);', content, re.DOTALL)

if viewmodels_group_match:
    viewmodels_group_id = viewmodels_group_match.group(1)
    children_content = viewmodels_group_match.group(2)

    # Check if Weight subfolder exists
    weight_folder_match = re.search(r'([A-F0-9]{24}) /\* Weight \*/', children_content)

    if weight_folder_match:
        weight_folder_id = weight_folder_match.group(1)
        print(f"✅ Found existing Weight folder: {weight_folder_id}")

        # Find Weight folder's children array
        weight_folder_pattern = rf'{weight_folder_id} /\* Weight \*/ = \{{[^}}]+children = \(\s*([^)]+)\s*\);'
        weight_folder_full_match = re.search(weight_folder_pattern, content, re.DOTALL)

        if weight_folder_full_match:
            weight_children = weight_folder_full_match.group(1)

            # Add file references to Weight folder's children
            new_children_refs = ""
            for filename in NEW_FILES:
                file_id = file_refs[filename]
                new_children_refs += f'\t\t\t\t{file_id} /* {filename} */,\n'

            # Insert new children
            updated_children = weight_children.rstrip() + "\n" + new_children_refs
            updated_weight_folder = weight_folder_full_match.group(0).replace(weight_children, updated_children)
            content = content.replace(weight_folder_full_match.group(0), updated_weight_folder)
            print("✅ Added files to Weight folder group")
    else:
        # Need to create Weight subfolder
        weight_folder_id = generate_xcode_id()
        print(f"⚠️  Creating new Weight folder: {weight_folder_id}")

        # Create Weight folder group
        weight_folder_children = ""
        for filename in NEW_FILES:
            file_id = file_refs[filename]
            weight_folder_children += f'\t\t\t\t{file_id} /* {filename} */,\n'

        weight_folder_group = f'''
\t\t{weight_folder_id} /* Weight */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{weight_folder_children}\t\t\t);
\t\t\tpath = Weight;
\t\t\tsourceTree = "<group>";
\t\t}};'''

        # Add Weight folder to ViewModels children
        viewmodels_full_match = re.search(rf'{viewmodels_group_id} /\* ViewModels \*/ = \{{[^}}]+children = \(\s*([^)]+)\s*\);', content, re.DOTALL)
        if viewmodels_full_match:
            viewmodels_children = viewmodels_full_match.group(1)
            updated_viewmodels_children = viewmodels_children.rstrip() + f"\n\t\t\t\t{weight_folder_id} /* Weight */,\n"
            content = content.replace(viewmodels_children, updated_viewmodels_children)

        # Add Weight folder group definition to PBXGroup section
        pbx_group_section_match = re.search(r'(/\* Begin PBXGroup section \*/.*?/\* End PBXGroup section \*/)', content, re.DOTALL)
        if pbx_group_section_match:
            pbx_group_section = pbx_group_section_match.group(1)
            updated_section = pbx_group_section.replace(
                "/* End PBXGroup section */",
                weight_folder_group + "\n\t/* End PBXGroup section */"
            )
            content = content.replace(pbx_group_section, updated_section)

        print("✅ Created Weight folder group")

# Step 5: Add files to Sources build phase
sources_build_phase_match = re.search(r'([A-F0-9]{24}) /\* Sources \*/ = \{[^}]+files = \(\s*([^)]+)\s*\);', content, re.DOTALL)

if sources_build_phase_match:
    sources_files = sources_build_phase_match.group(2)

    # Add build file references
    new_build_files = ""
    for filename in NEW_FILES:
        build_file_id = build_file_refs[filename]
        new_build_files += f'\t\t\t\t{build_file_id} /* {filename} in Sources */,\n'

    updated_sources_files = sources_files.rstrip() + "\n" + new_build_files
    updated_sources_phase = sources_build_phase_match.group(0).replace(sources_files, updated_sources_files)
    content = content.replace(sources_build_phase_match.group(0), updated_sources_phase)
    print("✅ Added files to Sources build phase")

# Write updated project file
with open(PROJECT_PATH, 'w') as f:
    f.write(content)

print(f"\n✅ Successfully added {len(NEW_FILES)} files to Xcode project!")
print("\nFiles added:")
for filename in NEW_FILES:
    print(f"  - {filename}")
