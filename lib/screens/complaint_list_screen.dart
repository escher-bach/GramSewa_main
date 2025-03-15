import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaints_app/theme/theme_provider.dart';
import 'navbar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  bool _isLoading = false;
  String _filterOption = 'All';
  final List<String> _filterOptions = ['All', 'Recent', 'My Complaints', 'Resolved', 'Unresolved'];
  
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onFabTap() async {
    _fabAnimationController.forward(from: 0);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Navigator.pushNamed(context, '/add_complaint');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipPath(
          clipper: CustomAppBarClipper(),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/appBar_bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  ColorPalette.primaryLight.withOpacity(0.9), 
                  BlendMode.srcOver,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDarkMode ? ColorPalette.primaryDark : ColorPalette.primaryLight,
                  isDarkMode 
                    ? ColorPalette.primaryDark.withOpacity(0.8) 
                    : ColorPalette.primaryLight.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          "Village Complaints",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              color: Colors.white,
            ),
            onPressed: () {
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      drawer: NavBar(),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_fabAnimationController.value * 0.2),
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _onFabTap,
              backgroundColor: ColorPalette.accentLight,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: Icon(Icons.add_circle_outlined),
              label: Text(
                "Add Complaint",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 16),
          
          // Filter options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final option = _filterOptions[index];
                  final isSelected = _filterOption == option;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filterOption = option;
                          });
                        }
                      },
                      backgroundColor: isDarkMode ? Colors.black12 : Colors.grey[200],
                      selectedColor: ColorPalette.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: 8),
          
          // Complaints list
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ColorPalette.primaryLight,
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: isDarkMode ? Colors.white30 : Colors.black12,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No complaints available",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Be the first to register a complaint",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final complaintData = doc.data() as Map<String, dynamic>;
                        
                        // Safely parse status or set default
                        final status = complaintData['status'] as String? ?? 'Pending';
                        final statusColor = _getStatusColor(status);
                        
                        // Parse timestamp from ISO string format
                        String timeAgo = 'Unknown time';
                        if (complaintData.containsKey('timestamp') && complaintData['timestamp'] != null) {
                          try {
                            // Parse ISO format string to DateTime
                            final timestampStr = complaintData['timestamp'] as String;
                            final dateTime = DateTime.parse(timestampStr);
                            timeAgo = timeago.format(dateTime);
                          } catch (e) {
                            print('Error parsing timestamp: $e');
                            timeAgo = 'Invalid date';
                          }
                        }
                        
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildComplaintCard(
                                  context, 
                                  doc, 
                                  complaintData, 
                                  timeAgo,
                                  status,
                                  statusColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComplaintCard(
    BuildContext context, 
    QueryDocumentSnapshot doc, 
    Map<String, dynamic> complaintData, 
    String timeAgo,
    String status,
    Color statusColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/open_complaint',
          arguments: {
            'complaintData': complaintData,
            'complaintId': doc.id,
          },
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 2,
        color: isDarkMode ? ColorPalette.surfaceDark : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and timestamp row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Complaint text
              Text(
                complaintData['text'] ?? "No description available",
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              
              // Bottom row with location and view details
              Row(
                children: [
                  // Location
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            complaintData.containsKey('location') 
                                ? complaintData['location']
                                : "Location not available",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // View details
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/open_complaint',
                        arguments: {
                          'complaintData': complaintData,
                          'complaintId': doc.id,
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "View Details",
                          style: TextStyle(
                            color: ColorPalette.primaryLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: ColorPalette.primaryLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch(status.toLowerCase()) {
      case 'resolved':
        return ColorPalette.success;
      case 'in progress':
        return ColorPalette.info;
      case 'rejected':
        return ColorPalette.error;
      case 'pending':
      default:
        return ColorPalette.warning;
    }
  }
}

class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    
    // Create a curved bottom edge
    path.quadraticBezierTo(
      size.width / 4, 
      size.height, 
      size.width / 2, 
      size.height - 10,
    );
    
    path.quadraticBezierTo(
      size.width * 3 / 4, 
      size.height - 20, 
      size.width, 
      size.height - 15,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}