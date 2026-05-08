"""Compact redesign patch for settings_screen.dart"""
import re

fp = r"d:\FlutterProjects\Family\lib\features\settings\presentation\settings_screen.dart"
with open(fp, "r", encoding="utf-8") as f:
    src = f.read()

# 1. Compact body ListView padding
src = src.replace(
    "      body: ListView(\n        padding: const EdgeInsets.all(16),",
    "      body: ListView(\n        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),",
)

# 2. Profile card: radius 28 → 22, padding all(16) → symmetric(h12,v10)
src = src.replace(
    "            child: Padding(\n              padding: const EdgeInsets.all(16),\n              child: Row(\n                children: [\n                  CircleAvatar(\n                    radius: 28,",
    "            child: Padding(\n              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),\n              child: Row(\n                children: [\n                  CircleAvatar(\n                    radius: 22,",
)

# 3. Avatar font size 24 → 20
src = src.replace(
    "                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),",
    "                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),",
)

# 4. SizedBox width 12 → 10 (after avatar)
src = src.replace(
    "                  const SizedBox(width: 12),\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(profile?.displayName ?? 'Thành viên',\n                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),\n                        const SizedBox(height: 2),\n                        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),\n                        const SizedBox(height: 2),\n                        Text('Vai trò: ${profile?.role.name ?? '-'}',\n                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),",
    "                  const SizedBox(width: 10),\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(profile?.displayName ?? 'Thành viên',\n                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),\n                        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),\n                        Text('Vai trò: \${profile?.role.name ?? '-'}',\n                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontSize: 11)),",
)

# 5. Account actions card: SizedBox height 8 → 6
src = src.replace(
    "          const SizedBox(height: 8),\n          Card(\n            child: Column(\n              children: [\n                ListTile(\n                  leading: const Icon(Icons.lock_reset_outlined),\n                  title: const Text('Đổi mật khẩu'),",
    "          const SizedBox(height: 6),\n          Card(\n            child: Column(\n              children: [\n                ListTile(\n                  dense: true,\n                  leading: const Icon(Icons.lock_reset_outlined, size: 20),\n                  title: const Text('Đổi mật khẩu'),",
)

# 6. Password tile trailing
src = src.replace(
    "                  onTap: _changePassword,\n                  trailing: const Icon(Icons.chevron_right),\n                ),\n                const Divider(height: 1, indent: 52),\n                ListTile(\n                  leading: const Icon(Icons.link_outlined),\n                  title: const Text('Liên kết tài khoản Google'),\n                  subtitle: Text(linkedGoogle ? 'Đã liên kết Google' : 'Chưa liên kết'),\n                  trailing: _linkingGoogle\n                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))\n                      : const Icon(Icons.chevron_right),",
    "                  onTap: _changePassword,\n                  trailing: const Icon(Icons.chevron_right, size: 18),\n                ),\n                const Divider(height: 1, indent: 48),\n                ListTile(\n                  dense: true,\n                  leading: const Icon(Icons.link_outlined, size: 20),\n                  title: const Text('Liên kết Google'),\n                  subtitle: Text(linkedGoogle ? 'Đã liên kết Google' : 'Chưa liên kết',\n                      style: const TextStyle(fontSize: 11)),\n                  trailing: _linkingGoogle\n                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))\n                      : const Icon(Icons.chevron_right, size: 18),",
)

# 7. Display section gap 20→12
src = src.replace(
    "          // ── Hiển thị ──────────────────────────────────────\n          const SizedBox(height: 20),\n          _SectionHeader(label: 'Hiển thị'),\n          Card(\n            child: ListTile(\n              leading: const Icon(Icons.brightness_medium_outlined),",
    "          // ── Hiển thị ──────────────────────────────────────\n          const SizedBox(height: 12),\n          _SectionHeader(label: 'Hiển thị'),\n          Card(\n            child: ListTile(\n              dense: true,\n              leading: const Icon(Icons.brightness_medium_outlined, size: 20),",
)

# 8. Data section gap 20→12
src = src.replace(
    "          // ── Dữ liệu ───────────────────────────────────────\n          const SizedBox(height: 20),\n          _SectionHeader(label: 'Dữ liệu'),\n          Card(\n            child: Column(\n              children: [\n                ListTile(\n                  leading: const Icon(Icons.backup_outlined),\n                  title: const Text('Sao lưu dữ liệu'),\n                  subtitle: const Text('Xuất file JSON qua share sheet'),\n                  trailing: const Icon(Icons.chevron_right),",
    "          // ── Dữ liệu ───────────────────────────────────────\n          const SizedBox(height: 12),\n          _SectionHeader(label: 'Dữ liệu'),\n          Card(\n            child: Column(\n              children: [\n                ListTile(\n                  dense: true,\n                  leading: const Icon(Icons.backup_outlined, size: 20),\n                  title: const Text('Sao lưu dữ liệu'),\n                  subtitle: const Text('Xuất file JSON qua share sheet', style: TextStyle(fontSize: 11)),\n                  trailing: const Icon(Icons.chevron_right, size: 18),",
)

# 9. App section gap 20→12
src = src.replace(
    "          // ── Ứng dụng ──────────────────────────────────────\n          const SizedBox(height: 20),\n          _SectionHeader(label: 'Ứng dụng'),\n          Card(\n            child: Column(\n              children: [\n                ListTile(\n                  leading: const Icon(Icons.info_outline),\n                  title: const Text('Phiên bản'),\n                  trailing: Text(_appVersion, style: const TextStyle(color: AppColors.textSecondary)),\n                ),\n                const Divider(height: 1, indent: 52),\n                ListTile(\n                  leading: const Icon(Icons.description_outlined),\n                  title: const Text('Điều khoản sử dụng'),\n                  trailing: const Icon(Icons.chevron_right),",
    "          // ── Ứng dụng ──────────────────────────────────────\n          const SizedBox(height: 12),\n          _SectionHeader(label: 'Ứng dụng'),\n          Card(\n            child: Column(\n              children: [\n                ListTile(\n                  dense: true,\n                  leading: const Icon(Icons.info_outline, size: 20),\n                  title: const Text('Phiên bản'),\n                  trailing: Text(_appVersion, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),\n                ),\n                const Divider(height: 1, indent: 48),\n                ListTile(\n                  dense: true,\n                  leading: const Icon(Icons.description_outlined, size: 20),\n                  title: const Text('Điều khoản sử dụng'),\n                  trailing: const Icon(Icons.chevron_right, size: 18),",
)

# 10. Privacy tile
src = src.replace(
    "                const Divider(height: 1, indent: 52),\n                ListTile(\n                  leading: const Icon(Icons.privacy_tip_outlined),\n                  title: const Text('Chính sách bảo mật'),\n                  trailing: const Icon(Icons.chevron_right),",
    "                const Divider(height: 1, indent: 48),\n                ListTile(\n                  dense: true,\n                  leading: const Icon(Icons.privacy_tip_outlined, size: 20),\n                  title: const Text('Chính sách bảo mật'),\n                  trailing: const Icon(Icons.chevron_right, size: 18),",
)

# 11. Danger zone SizedBox 32→20
src = src.replace(
    "          // ── Nguy hiểm ─────────────────────────────────────\n          const SizedBox(height: 32),",
    "          // ── Nguy hiểm ─────────────────────────────────────\n          const SizedBox(height: 20),",
)

with open(fp, "w", encoding="utf-8") as f:
    f.write(src)

print("Done patching settings_screen.dart")
