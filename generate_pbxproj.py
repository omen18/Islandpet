#!/usr/bin/env python3
"""
generate_pbxproj.py
Produces IslandPet.xcodeproj/project.pbxproj from the source tree.

Usage:
    python3 generate_pbxproj.py
Then open IslandPet.xcodeproj in Xcode.

This generator is intentionally conservative: it only produces a project
that contains two native targets (app + widget extension), the SwiftData /
ActivityKit / WidgetKit / SwiftUI frameworks (linked implicitly via SDK),
and the necessary file references. It does NOT yet add Swift Package
dependencies — to add Rive, use Xcode's UI: File ▸ Add Package Dependencies…
"""

import os, hashlib, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJECT_NAME = "IslandPet"

def uid(s: str) -> str:
    """Deterministic 24-char uppercase hex UUID."""
    return hashlib.md5(s.encode()).hexdigest()[:24].upper()

def list_swift(base: str):
    out = []
    for dirpath, _, files in os.walk(os.path.join(ROOT, base)):
        for f in sorted(files):
            if f.endswith(".swift"):
                rel = os.path.relpath(os.path.join(dirpath, f), ROOT)
                out.append(rel)
    return sorted(out)

APP_DIR = "IslandPet"
WIDGET_DIR = "IslandPetWidget"
SHARED_DIR = "Shared"

app_swift = list_swift(APP_DIR)
widget_swift = list_swift(WIDGET_DIR)
shared_swift = list_swift(SHARED_DIR)

# Files membership rules:
#   APP target:    app_swift + shared_swift
#   WIDGET target: widget_swift + shared_swift   (Shared is in BOTH targets)
APP_SOURCES = app_swift + shared_swift
WIDGET_SOURCES = widget_swift + shared_swift

# ─────────────────────────────────────────────────────────────
# Project IDs (stable, deterministic)
# ─────────────────────────────────────────────────────────────
PROJECT_ID            = uid("project")
MAIN_GROUP_ID         = uid("mainGroup")
PRODUCTS_GROUP_ID     = uid("productsGroup")
APP_GROUP_ID          = uid("appGroup")
WIDGET_GROUP_ID       = uid("widgetGroup")
SHARED_GROUP_ID       = uid("sharedGroup")
RESOURCES_GROUP_ID    = uid("resourcesGroup")

APP_TARGET_ID         = uid("appTarget")
WIDGET_TARGET_ID      = uid("widgetTarget")

APP_PRODUCT_ID        = uid("appProduct")
WIDGET_PRODUCT_ID     = uid("widgetProduct")

APP_SOURCES_PHASE_ID  = uid("appSourcesPhase")
APP_FRAMEWORKS_PHASE  = uid("appFrameworksPhase")
APP_RESOURCES_PHASE   = uid("appResourcesPhase")
APP_EMBED_EXT_PHASE   = uid("appEmbedExtPhase")

WIDGET_SOURCES_PHASE  = uid("widgetSourcesPhase")
WIDGET_FRAMEWORKS     = uid("widgetFrameworksPhase")
WIDGET_RESOURCES      = uid("widgetResourcesPhase")

APP_INFO_REF          = uid("appInfoRef")
APP_ENT_REF           = uid("appEntitlementsRef")
WIDGET_INFO_REF       = uid("widgetInfoRef")
WIDGET_ENT_REF        = uid("widgetEntitlementsRef")
ASSETS_REF            = uid("assetsRef")

PROJECT_CONFIG_LIST   = uid("projectConfigList")
PROJECT_DEBUG         = uid("projectDebug")
PROJECT_RELEASE       = uid("projectRelease")
APP_CONFIG_LIST       = uid("appConfigList")
APP_DEBUG             = uid("appDebug")
APP_RELEASE           = uid("appRelease")
WIDGET_CONFIG_LIST    = uid("widgetConfigList")
WIDGET_DEBUG          = uid("widgetDebug")
WIDGET_RELEASE        = uid("widgetRelease")

DEP_PROXY_ID          = uid("depProxy")
DEP_TARGET_ID         = uid("depTarget")
EMBED_BUILD_FILE_ID   = uid("embedBuildFile")

# ─────────────────────────────────────────────────────────────
# Build the lookup table for file references and build files
# ─────────────────────────────────────────────────────────────

# For each source file we need: a PBXFileReference + a PBXBuildFile per
# membership.  Shared sources have ONE file reference, but TWO build files
# (one per target) so they appear in both Sources phases.

class Ref:
    def __init__(self, path, file_ref_id, group_id, name):
        self.path = path
        self.file_ref_id = file_ref_id
        self.group_id = group_id
        self.name = name
        self.app_build_file_id = None
        self.widget_build_file_id = None

refs = {}

def get_ref(path, group_id):
    if path in refs:
        return refs[path]
    name = os.path.basename(path)
    r = Ref(path=path, file_ref_id=uid("fr:" + path), group_id=group_id, name=name)
    refs[path] = r
    return r

# Group each path under a group id keyed by its directory
def group_for(path):
    if path.startswith(APP_DIR + "/"):    return uid("group:" + os.path.dirname(path))
    if path.startswith(WIDGET_DIR + "/"): return uid("group:" + os.path.dirname(path))
    if path.startswith(SHARED_DIR):       return SHARED_GROUP_ID
    return MAIN_GROUP_ID

# Register build-file IDs
for p in APP_SOURCES:
    r = get_ref(p, group_for(p))
    r.app_build_file_id = uid("bf:app:" + p)

for p in WIDGET_SOURCES:
    r = get_ref(p, group_for(p))
    r.widget_build_file_id = uid("bf:widget:" + p)

# Build a tree of groups so files appear nicely in the navigator.
class Group:
    def __init__(self, gid, name, path=None, parent=None):
        self.gid = gid
        self.name = name
        self.path = path
        self.parent = parent
        self.children = []   # list of (kind, id) where kind ∈ {"group", "file"}

groups = {}

def ensure_group(rel_dir: str, parent: "Group") -> Group:
    """rel_dir is like 'IslandPet/Views/Home'"""
    if rel_dir in groups:
        return groups[rel_dir]
    name = os.path.basename(rel_dir) or rel_dir
    gid = uid("group:" + rel_dir)
    g = Group(gid=gid, name=name, path=name, parent=parent)
    groups[rel_dir] = g
    parent.children.append(("group", g.gid))
    return g

# Roots
main_group = Group(MAIN_GROUP_ID, "", path=None)
products_group = Group(PRODUCTS_GROUP_ID, "Products", path=None, parent=main_group)
groups["__products__"] = products_group
main_group.children.append(("group", products_group.gid))

# Top-level groups: IslandPet/, IslandPetWidget/, Shared/
app_group = Group(APP_GROUP_ID, APP_DIR, path=APP_DIR, parent=main_group)
groups[APP_DIR] = app_group
main_group.children.insert(0, ("group", app_group.gid))

widget_group = Group(WIDGET_GROUP_ID, WIDGET_DIR, path=WIDGET_DIR, parent=main_group)
groups[WIDGET_DIR] = widget_group
main_group.children.insert(1, ("group", widget_group.gid))

shared_group = Group(SHARED_GROUP_ID, SHARED_DIR, path=SHARED_DIR, parent=main_group)
groups[SHARED_DIR] = shared_group
main_group.children.insert(2, ("group", shared_group.gid))

def walk_into(rel_path: str):
    """Ensure all directory groups exist down to rel_path (a file path)."""
    parts = rel_path.split("/")
    cur_path = ""
    parent = main_group
    for i, part in enumerate(parts[:-1]):
        cur_path = os.path.join(cur_path, part) if cur_path else part
        if cur_path == APP_DIR:
            parent = app_group
            continue
        if cur_path == WIDGET_DIR:
            parent = widget_group
            continue
        if cur_path == SHARED_DIR:
            parent = shared_group
            continue
        if cur_path in groups:
            parent = groups[cur_path]
            continue
        gid = uid("group:" + cur_path)
        g = Group(gid=gid, name=part, path=part, parent=parent)
        groups[cur_path] = g
        parent.children.append(("group", g.gid))
        parent = g
    return parent

# Place each Swift file into its group
for p, r in refs.items():
    parent = walk_into(p)
    parent.children.append(("file", r.file_ref_id))

# Add other resources/info plists into the App group manually
# Info.plist
app_info_path = "IslandPet/Resources/Info.plist"
app_ent_path  = "IslandPet/Resources/IslandPet.entitlements"
widget_info_path = "IslandPetWidget/Info.plist"
widget_ent_path  = "IslandPetWidget/IslandPetWidget.entitlements"
assets_path = "IslandPet/Resources/Assets.xcassets"

# Create an explicit Resources group under the app
resources_group = Group(RESOURCES_GROUP_ID, "Resources", path="Resources", parent=app_group)
groups["IslandPet/Resources"] = resources_group
app_group.children.append(("group", resources_group.gid))

resources_group.children.append(("file", APP_INFO_REF))
resources_group.children.append(("file", APP_ENT_REF))
resources_group.children.append(("file", ASSETS_REF))

widget_group.children.append(("file", WIDGET_INFO_REF))
widget_group.children.append(("file", WIDGET_ENT_REF))

# Products (the .app and .appex)
products_group.children.append(("file", APP_PRODUCT_ID))
products_group.children.append(("file", WIDGET_PRODUCT_ID))

# ─────────────────────────────────────────────────────────────
# Render the .pbxproj
# ─────────────────────────────────────────────────────────────

def fr_line(file_id, name, path, file_type, source_tree="<group>"):
    return (f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; '
            f'lastKnownFileType = {file_type}; name = "{name}"; '
            f'path = "{path}"; sourceTree = "{source_tree}"; }};')

def bf_line(bf_id, file_ref_id, name, target_label):
    return (f'\t\t{bf_id} /* {name} in Sources [{target_label}] */ = '
            f'{{isa = PBXBuildFile; fileRef = {file_ref_id} /* {name} */; }};')

# Begin output
out = []
out.append('// !$*UTF8*$!')
out.append('{')
out.append('\tarchiveVersion = 1;')
out.append('\tclasses = {};')
out.append('\tobjectVersion = 56;')
out.append('\tobjects = {')

# ── PBXBuildFile section ──
out.append('')
out.append('/* Begin PBXBuildFile section */')
for r in refs.values():
    if r.app_build_file_id:
        out.append(bf_line(r.app_build_file_id, r.file_ref_id, r.name, "App"))
    if r.widget_build_file_id:
        out.append(bf_line(r.widget_build_file_id, r.file_ref_id, r.name, "Widget"))
# Resources build file: assets in app
ASSETS_BF = uid("bf:assets")
out.append(f'\t\t{ASSETS_BF} /* Assets.xcassets in Resources [App] */ = '
           f'{{isa = PBXBuildFile; fileRef = {ASSETS_REF} /* Assets.xcassets */; }};')
# Embed extension
out.append(f'\t\t{EMBED_BUILD_FILE_ID} /* IslandPetWidgetExtension.appex in Embed Foundation Extensions */ = '
           f'{{isa = PBXBuildFile; fileRef = {WIDGET_PRODUCT_ID} /* IslandPetWidgetExtension.appex */; '
           f'settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};')
out.append('/* End PBXBuildFile section */')

# ── PBXContainerItemProxy ──
out.append('')
out.append('/* Begin PBXContainerItemProxy section */')
out.append(f'\t\t{DEP_PROXY_ID} /* PBXContainerItemProxy */ = {{')
out.append('\t\t\tisa = PBXContainerItemProxy;')
out.append(f'\t\t\tcontainerPortal = {PROJECT_ID} /* Project object */;')
out.append('\t\t\tproxyType = 1;')
out.append(f'\t\t\tremoteGlobalIDString = {WIDGET_TARGET_ID};')
out.append('\t\t\tremoteInfo = IslandPetWidgetExtension;')
out.append('\t\t};')
out.append('/* End PBXContainerItemProxy section */')

# ── PBXCopyFilesBuildPhase (Embed Extensions) ──
out.append('')
out.append('/* Begin PBXCopyFilesBuildPhase section */')
out.append(f'\t\t{APP_EMBED_EXT_PHASE} /* Embed Foundation Extensions */ = {{')
out.append('\t\t\tisa = PBXCopyFilesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tdstPath = "";')
out.append('\t\t\tdstSubfolderSpec = 13;')
out.append('\t\t\tfiles = (')
out.append(f'\t\t\t\t{EMBED_BUILD_FILE_ID} /* IslandPetWidgetExtension.appex in Embed Foundation Extensions */,')
out.append('\t\t\t);')
out.append('\t\t\tname = "Embed Foundation Extensions";')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXCopyFilesBuildPhase section */')

# ── PBXFileReference section ──
out.append('')
out.append('/* Begin PBXFileReference section */')
for r in refs.values():
    out.append(fr_line(r.file_ref_id, r.name, os.path.basename(r.path),
                       "sourcecode.swift"))
# Plists / entitlements / assets
out.append(fr_line(APP_INFO_REF, "Info.plist", "Info.plist", "text.plist.xml"))
out.append(fr_line(APP_ENT_REF, "IslandPet.entitlements", "IslandPet.entitlements",
                   "text.plist.entitlements"))
out.append(fr_line(WIDGET_INFO_REF, "Info.plist", "Info.plist", "text.plist.xml"))
out.append(fr_line(WIDGET_ENT_REF, "IslandPetWidget.entitlements",
                   "IslandPetWidget.entitlements", "text.plist.entitlements"))
out.append(fr_line(ASSETS_REF, "Assets.xcassets", "Assets.xcassets",
                   "folder.assetcatalog"))
# Products
out.append(f'\t\t{APP_PRODUCT_ID} /* IslandPet.app */ = {{isa = PBXFileReference; '
           f'explicitFileType = wrapper.application; includeInIndex = 0; '
           f'path = IslandPet.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
out.append(f'\t\t{WIDGET_PRODUCT_ID} /* IslandPetWidgetExtension.appex */ = {{isa = PBXFileReference; '
           f'explicitFileType = "wrapper.app-extension"; includeInIndex = 0; '
           f'path = IslandPetWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
out.append('/* End PBXFileReference section */')

# ── PBXFrameworksBuildPhase ──
out.append('')
out.append('/* Begin PBXFrameworksBuildPhase section */')
out.append(f'\t\t{APP_FRAMEWORKS_PHASE} /* Frameworks */ = {{')
out.append('\t\t\tisa = PBXFrameworksBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append(f'\t\t{WIDGET_FRAMEWORKS} /* Frameworks */ = {{')
out.append('\t\t\tisa = PBXFrameworksBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXFrameworksBuildPhase section */')

# ── PBXGroup section ──
out.append('')
out.append('/* Begin PBXGroup section */')

def render_group(g: Group):
    lines = []
    lines.append(f'\t\t{g.gid} /* {g.name} */ = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    for kind, cid in g.children:
        if kind == "group":
            child = next((x for x in groups.values() if x.gid == cid), None)
            label = child.name if child else cid
            lines.append(f'\t\t\t\t{cid} /* {label} */,')
        else:
            # find file
            ref = next((r for r in refs.values() if r.file_ref_id == cid), None)
            if ref:
                lines.append(f'\t\t\t\t{cid} /* {ref.name} */,')
            elif cid == APP_INFO_REF:
                lines.append(f'\t\t\t\t{cid} /* Info.plist */,')
            elif cid == APP_ENT_REF:
                lines.append(f'\t\t\t\t{cid} /* IslandPet.entitlements */,')
            elif cid == WIDGET_INFO_REF:
                lines.append(f'\t\t\t\t{cid} /* Info.plist */,')
            elif cid == WIDGET_ENT_REF:
                lines.append(f'\t\t\t\t{cid} /* IslandPetWidget.entitlements */,')
            elif cid == ASSETS_REF:
                lines.append(f'\t\t\t\t{cid} /* Assets.xcassets */,')
            elif cid == APP_PRODUCT_ID:
                lines.append(f'\t\t\t\t{cid} /* IslandPet.app */,')
            elif cid == WIDGET_PRODUCT_ID:
                lines.append(f'\t\t\t\t{cid} /* IslandPetWidgetExtension.appex */,')
            else:
                lines.append(f'\t\t\t\t{cid},')
    lines.append('\t\t\t);')
    if g.path:
        lines.append(f'\t\t\tpath = "{g.path}";')
    elif g.name:
        lines.append(f'\t\t\tname = "{g.name}";')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')
    return "\n".join(lines)

# main group has no path/name
out.append(f'\t\t{main_group.gid} = {{')
out.append('\t\t\tisa = PBXGroup;')
out.append('\t\t\tchildren = (')
for kind, cid in main_group.children:
    if kind == "group":
        child = next((x for x in groups.values() if x.gid == cid), None)
        label = child.name if child else cid
        out.append(f'\t\t\t\t{cid} /* {label} */,')
out.append('\t\t\t);')
out.append('\t\t\tsourceTree = "<group>";')
out.append('\t\t};')

# all child groups
for g in groups.values():
    if g is main_group:
        continue
    out.append(render_group(g))

out.append('/* End PBXGroup section */')

# ── PBXNativeTarget ──
out.append('')
out.append('/* Begin PBXNativeTarget section */')
out.append(f'\t\t{APP_TARGET_ID} /* IslandPet */ = {{')
out.append('\t\t\tisa = PBXNativeTarget;')
out.append(f'\t\t\tbuildConfigurationList = {APP_CONFIG_LIST} /* Build configuration list for PBXNativeTarget "IslandPet" */;')
out.append('\t\t\tbuildPhases = (')
out.append(f'\t\t\t\t{APP_SOURCES_PHASE_ID} /* Sources */,')
out.append(f'\t\t\t\t{APP_FRAMEWORKS_PHASE} /* Frameworks */,')
out.append(f'\t\t\t\t{APP_RESOURCES_PHASE} /* Resources */,')
out.append(f'\t\t\t\t{APP_EMBED_EXT_PHASE} /* Embed Foundation Extensions */,')
out.append('\t\t\t);')
out.append('\t\t\tbuildRules = ();')
out.append('\t\t\tdependencies = (')
out.append(f'\t\t\t\t{DEP_TARGET_ID} /* PBXTargetDependency */,')
out.append('\t\t\t);')
out.append('\t\t\tname = IslandPet;')
out.append('\t\t\tproductName = IslandPet;')
out.append(f'\t\t\tproductReference = {APP_PRODUCT_ID} /* IslandPet.app */;')
out.append('\t\t\tproductType = "com.apple.product-type.application";')
out.append('\t\t};')

out.append(f'\t\t{WIDGET_TARGET_ID} /* IslandPetWidgetExtension */ = {{')
out.append('\t\t\tisa = PBXNativeTarget;')
out.append(f'\t\t\tbuildConfigurationList = {WIDGET_CONFIG_LIST} /* Build configuration list for PBXNativeTarget "IslandPetWidgetExtension" */;')
out.append('\t\t\tbuildPhases = (')
out.append(f'\t\t\t\t{WIDGET_SOURCES_PHASE} /* Sources */,')
out.append(f'\t\t\t\t{WIDGET_FRAMEWORKS} /* Frameworks */,')
out.append(f'\t\t\t\t{WIDGET_RESOURCES} /* Resources */,')
out.append('\t\t\t);')
out.append('\t\t\tbuildRules = ();')
out.append('\t\t\tdependencies = ();')
out.append('\t\t\tname = IslandPetWidgetExtension;')
out.append('\t\t\tproductName = IslandPetWidgetExtension;')
out.append(f'\t\t\tproductReference = {WIDGET_PRODUCT_ID} /* IslandPetWidgetExtension.appex */;')
out.append('\t\t\tproductType = "com.apple.product-type.app-extension";')
out.append('\t\t};')
out.append('/* End PBXNativeTarget section */')

# ── PBXProject ──
out.append('')
out.append('/* Begin PBXProject section */')
out.append(f'\t\t{PROJECT_ID} /* Project object */ = {{')
out.append('\t\t\tisa = PBXProject;')
out.append('\t\t\tattributes = {')
out.append('\t\t\t\tBuildIndependentTargetsInParallel = 1;')
out.append('\t\t\t\tLastSwiftUpdateCheck = 1500;')
out.append('\t\t\t\tLastUpgradeCheck = 1500;')
out.append('\t\t\t\tTargetAttributes = {')
out.append(f'\t\t\t\t\t{APP_TARGET_ID} = {{ CreatedOnToolsVersion = 15.0; }};')
out.append(f'\t\t\t\t\t{WIDGET_TARGET_ID} = {{ CreatedOnToolsVersion = 15.0; }};')
out.append('\t\t\t\t};')
out.append('\t\t\t};')
out.append(f'\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject "IslandPet" */;')
out.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
out.append('\t\t\tdevelopmentRegion = en;')
out.append('\t\t\thasScannedForEncodings = 0;')
out.append('\t\t\tknownRegions = ( en, Base, );')
out.append(f'\t\t\tmainGroup = {MAIN_GROUP_ID};')
out.append(f'\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;')
out.append('\t\t\tprojectDirPath = "";')
out.append('\t\t\tprojectRoot = "";')
out.append('\t\t\ttargets = (')
out.append(f'\t\t\t\t{APP_TARGET_ID} /* IslandPet */,')
out.append(f'\t\t\t\t{WIDGET_TARGET_ID} /* IslandPetWidgetExtension */,')
out.append('\t\t\t);')
out.append('\t\t};')
out.append('/* End PBXProject section */')

# ── PBXResourcesBuildPhase ──
out.append('')
out.append('/* Begin PBXResourcesBuildPhase section */')
out.append(f'\t\t{APP_RESOURCES_PHASE} /* Resources */ = {{')
out.append('\t\t\tisa = PBXResourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = (')
out.append(f'\t\t\t\t{ASSETS_BF} /* Assets.xcassets in Resources [App] */,')
out.append('\t\t\t);')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append(f'\t\t{WIDGET_RESOURCES} /* Resources */ = {{')
out.append('\t\t\tisa = PBXResourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXResourcesBuildPhase section */')

# ── PBXSourcesBuildPhase ──
out.append('')
out.append('/* Begin PBXSourcesBuildPhase section */')
out.append(f'\t\t{APP_SOURCES_PHASE_ID} /* Sources */ = {{')
out.append('\t\t\tisa = PBXSourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = (')
for r in refs.values():
    if r.app_build_file_id:
        out.append(f'\t\t\t\t{r.app_build_file_id} /* {r.name} in Sources [App] */,')
out.append('\t\t\t);')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')

out.append(f'\t\t{WIDGET_SOURCES_PHASE} /* Sources */ = {{')
out.append('\t\t\tisa = PBXSourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = (')
for r in refs.values():
    if r.widget_build_file_id:
        out.append(f'\t\t\t\t{r.widget_build_file_id} /* {r.name} in Sources [Widget] */,')
out.append('\t\t\t);')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXSourcesBuildPhase section */')

# ── PBXTargetDependency ──
out.append('')
out.append('/* Begin PBXTargetDependency section */')
out.append(f'\t\t{DEP_TARGET_ID} /* PBXTargetDependency */ = {{')
out.append('\t\t\tisa = PBXTargetDependency;')
out.append(f'\t\t\ttarget = {WIDGET_TARGET_ID} /* IslandPetWidgetExtension */;')
out.append(f'\t\t\ttargetProxy = {DEP_PROXY_ID} /* PBXContainerItemProxy */;')
out.append('\t\t};')
out.append('/* End PBXTargetDependency section */')

# ── XCBuildConfiguration section ──
common_settings = """\
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.10;
"""

debug_extra = """\
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ( "DEBUG=1", "$(inherited)" );
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = ( "DEBUG", "$(inherited)" );
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
"""

release_extra = """\
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
"""

out.append('')
out.append('/* Begin XCBuildConfiguration section */')

# Project-level Debug
out.append(f'\t\t{PROJECT_DEBUG} /* Debug */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append(common_settings + debug_extra)
out.append('\t\t\t};')
out.append('\t\t\tname = Debug;')
out.append('\t\t};')

out.append(f'\t\t{PROJECT_RELEASE} /* Release */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append(common_settings + release_extra)
out.append('\t\t\t};')
out.append('\t\t\tname = Release;')
out.append('\t\t};')

# App target Debug/Release
app_settings = """\
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "IslandPet/Resources/IslandPet.entitlements";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "IslandPet/Resources/Info.plist";
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ( "$(inherited)", "@executable_path/Frameworks", );
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.islandpet.app";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSUPPORTS_MACCATALYST = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.10;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
"""

out.append(f'\t\t{APP_DEBUG} /* Debug */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append(app_settings)
out.append('\t\t\t};')
out.append('\t\t\tname = Debug;')
out.append('\t\t};')
out.append(f'\t\t{APP_RELEASE} /* Release */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append(app_settings)
out.append('\t\t\t};')
out.append('\t\t\tname = Release;')
out.append('\t\t};')

# Widget target Debug/Release
widget_settings = """\
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "IslandPetWidget/IslandPetWidget.entitlements";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "IslandPetWidget/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ( "$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks", );
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.islandpet.app.widget";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSUPPORTS_MACCATALYST = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.10;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
"""

out.append(f'\t\t{WIDGET_DEBUG} /* Debug */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append(widget_settings)
out.append('\t\t\t};')
out.append('\t\t\tname = Debug;')
out.append('\t\t};')
out.append(f'\t\t{WIDGET_RELEASE} /* Release */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append(widget_settings)
out.append('\t\t\t};')
out.append('\t\t\tname = Release;')
out.append('\t\t};')
out.append('/* End XCBuildConfiguration section */')

# ── XCConfigurationList ──
out.append('')
out.append('/* Begin XCConfigurationList section */')

def cfg_list(cl_id, debug_id, release_id, label):
    out.append(f'\t\t{cl_id} /* Build configuration list for {label} */ = {{')
    out.append('\t\t\tisa = XCConfigurationList;')
    out.append('\t\t\tbuildConfigurations = (')
    out.append(f'\t\t\t\t{debug_id} /* Debug */,')
    out.append(f'\t\t\t\t{release_id} /* Release */,')
    out.append('\t\t\t);')
    out.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    out.append('\t\t\tdefaultConfigurationName = Release;')
    out.append('\t\t};')

cfg_list(PROJECT_CONFIG_LIST, PROJECT_DEBUG, PROJECT_RELEASE,
         'PBXProject "IslandPet"')
cfg_list(APP_CONFIG_LIST, APP_DEBUG, APP_RELEASE,
         'PBXNativeTarget "IslandPet"')
cfg_list(WIDGET_CONFIG_LIST, WIDGET_DEBUG, WIDGET_RELEASE,
         'PBXNativeTarget "IslandPetWidgetExtension"')
out.append('/* End XCConfigurationList section */')

# Close
out.append('\t};')
out.append(f'\trootObject = {PROJECT_ID} /* Project object */;')
out.append('}')

# Write
proj_dir = os.path.join(ROOT, "IslandPet.xcodeproj")
os.makedirs(proj_dir, exist_ok=True)
with open(os.path.join(proj_dir, "project.pbxproj"), "w") as f:
    f.write("\n".join(out) + "\n")

# Write workspace metadata
ws_dir = os.path.join(proj_dir, "project.xcworkspace")
os.makedirs(ws_dir, exist_ok=True)
with open(os.path.join(ws_dir, "contents.xcworkspacedata"), "w") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    f.write('<Workspace version="1.0">\n')
    f.write('  <FileRef location="self:"></FileRef>\n')
    f.write('</Workspace>\n')

# Shared scheme
schemes_dir = os.path.join(proj_dir, "xcshareddata", "xcschemes")
os.makedirs(schemes_dir, exist_ok=True)
scheme_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{APP_TARGET_ID}"
               BuildableName = "IslandPet.app"
               BlueprintName = "IslandPet"
               ReferencedContainer = "container:IslandPet.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables></Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{APP_TARGET_ID}"
            BuildableName = "IslandPet.app"
            BlueprintName = "IslandPet"
            ReferencedContainer = "container:IslandPet.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{APP_TARGET_ID}"
            BuildableName = "IslandPet.app"
            BlueprintName = "IslandPet"
            ReferencedContainer = "container:IslandPet.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"></ArchiveAction>
</Scheme>
'''
with open(os.path.join(schemes_dir, "IslandPet.xcscheme"), "w") as f:
    f.write(scheme_xml)

print(f"Wrote {os.path.join(proj_dir, 'project.pbxproj')}")
print(f"App sources: {sum(1 for r in refs.values() if r.app_build_file_id)}")
print(f"Widget sources: {sum(1 for r in refs.values() if r.widget_build_file_id)}")
