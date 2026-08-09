import 'package:flutter/material.dart';
import '../utils/app_icons.dart';



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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.users, size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text(
                  "$activeCount of $maxCapacity profiles used",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: user.isPlusActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: user.isPlusActive ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                user.isPlusActive ? "Specz Plus" : "Free Plan",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: user.isPlusActive ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 68,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...profiles.map((profile) {
                bool isSelected = selectedProfile?.id == profile.id;
                return GestureDetector(
                  onTap: () => onSelectProfile(profile),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFE0F2FE),
                          child: Icon(
                            profile.type == 'Child' ? LucideIcons.baby : LucideIcons.user,
                            size: 18,
                            color: isSelected ? Colors.white : const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              profile.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              "${profile.relationship} (${profile.type})",
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: onAddProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: canAdd ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canAdd ? const Color(0xFFBBF7D0) : const Color(0xFFFCA5A5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canAdd ? LucideIcons.plusCircle : LucideIcons.lock,
                        size: 18,
                        color: canAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        canAdd ? "Add Profile" : "Upgrade to Add",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
