//================== كود الدعوة ==================
import 'package:flutter/material.dart';

class InviteCodeContainer extends StatelessWidget {
  final String? _inviteCode;
  final VoidCallback _copyInviteCode;

  const InviteCodeContainer({
    super.key,
    required String? inviteCode,
    required VoidCallback copyInviteCode,
  }) : _inviteCode = inviteCode,
       _copyInviteCode = copyInviteCode;

  @override
  Widget build(BuildContext context) {
    //================== كود الدعوة ==================
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEEF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16213E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _copyInviteCode,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF16213E),
                  ),
                ),
              ),

              const Spacer(),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    "كود الدعوة",
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF16213E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "شارك هذا الكود مع المساعد",
                    style: TextStyle(
                      fontFamily: "cairo",
                      color: Color(0xFF9AA3B2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFF16213E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _inviteCode ?? "...",
                style: const TextStyle(
                  fontFamily: "cairo",
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 3,
                  color: Color(0xFF16213E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
