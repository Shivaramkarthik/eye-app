import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../utils/app_theme.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';

class ProfileSwitcherBar extends StatelessWidget {
  final List<ProfileModel> profiles;
  final ProfileModel? selectedProfile;
  final UserModel user;
  final Function(ProfileModel) onSelectProfile;
  final VoidCallback onAddProfile;

  const ProfileSwitcherBar({
    Key? key,
    required this.profiles,
    required this.selectedProfile,
    required this.user,
    required this.onSelectProfile,
    required this.onAddProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int activeCount = profiles.length;
    int maxCapacity = user.maxProfiles;
    bool canAdd = activeCount < maxCapacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.users, size: 14, color: AppTheme.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  "$activeCount of $maxCapacity profiles",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: user.isPlusActive ? AppTheme.warmGradient : null,
                color: user.isPlusActive ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isPlusActive ? "✨ Specz Plus" : "Free Plan",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: user.isPlusActive ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Profile chips
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              ...profiles.map((profile) {
                bool isSelected = selectedProfile?.id == profile.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => onSelectProfile(profile),
                    child: AnimatedContainer(
                      duration: AppTheme.animFast,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: isSelected ? AppTheme.primaryShadow : AppTheme.softShadow,
                        border: isSelected ? null : Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.primary.withOpacity(0.1),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.4)
                                    : AppTheme.primary.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              profile.type == 'Child' ? LucideIcons.baby : LucideIcons.user,
                              size: 18,
                              color: isSelected ? Colors.white : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${profile.relationship} · ${profile.type}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              // Add profile button
              GestureDetector(
                onTap: onAddProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: canAdd ? AppTheme.success.withOpacity(0.08) : AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: canAdd ? AppTheme.success.withOpacity(0.3) : AppTheme.error.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: canAdd ? AppTheme.success.withOpacity(0.5) : AppTheme.error.withOpacity(0.5),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Icon(
                          canAdd ? LucideIcons.plus : LucideIcons.lock,
                          size: 16,
                          color: canAdd ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canAdd ? "Add\nProfile" : "Upgrade\nto Add",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: canAdd ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
