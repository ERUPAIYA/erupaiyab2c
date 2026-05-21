// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';

String normalizeMobile(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

class ContactsList extends StatelessWidget {
  const ContactsList({
    super.key,
    required this.contacts,
    required this.visibleCount,
    required this.onSelect,
  });

  final List<Contact> contacts;
  final int visibleCount;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final displayContacts = contacts.length > visibleCount
        ? contacts.take(visibleCount).toList()
        : contacts;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displayContacts.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.black.withOpacity(0.06),
      ),
      itemBuilder: (context, index) {
        final contact = displayContacts[index];
        final phone =
            contact.phones.isNotEmpty ? contact.phones.first.number : '';
        final photoBytes = contact.photoOrThumbnail;
        return InkWell(
          onTap: phone.isEmpty ? null : () => onSelect(normalizeMobile(phone)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.black.withOpacity(0.08),
                  backgroundImage:
                      photoBytes == null ? null : MemoryImage(photoBytes),
                  child: photoBytes != null
                      ? null
                      : const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone.isEmpty ? 'No number' : phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                if (phone.isNotEmpty)
                  Image.asset(
                    FileConstants.tiltArrow,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
