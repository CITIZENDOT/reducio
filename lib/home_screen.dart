import 'package:flutter/material.dart';
import 'package:reducio/compress_tab.dart';
import 'package:reducio/remove_audio_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final double _tabBarHeight = 60.0; // Adjusted slightly
  final double _tabBarMaxWidth = 1000.0; // Max width for the TabBar itself
  final double _outerBorderWidth = 6, spaceBetweenBorders = 4;
  final double _innerBorderWidth = 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _tabController.previousIndex) {
        if (mounted) {
          // Ensure widget is still in the tree
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCompressSelected = _tabController.index == 0;
    final bool isRemoveAudioSelected = _tabController.index == 1;

    // Define a common style for tab text
    final tabTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 15, // Adjusted from previous
      // color will be handled by TabBarTheme or direct Tab styling
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 185, // Increased for more top spacing
        backgroundColor: theme.colorScheme.background,
        elevation: 3, // Slightly more pronounced shadow for the AppBar
        shadowColor: Colors.black.withOpacity(0.6),
        flexibleSpace: Container(
          padding: EdgeInsets.fromLTRB(
              spaceBetweenBorders, spaceBetweenBorders, spaceBetweenBorders, 0),
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: const Color(0xc0837C2F), width: _outerBorderWidth),
                  left: BorderSide(
                      color: const Color(0xc0837C2F), width: _outerBorderWidth),
                  right: BorderSide(
                      color: const Color(0xc0837C2F),
                      width: _outerBorderWidth))),
          child: Container(
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: const Color(0xc0EDE481),
                        width: _innerBorderWidth),
                    left: BorderSide(
                        color: const Color(0xc0EDE481),
                        width: _innerBorderWidth),
                    right: BorderSide(
                        color: const Color(0xc0EDE481),
                        width: _innerBorderWidth))),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the title block vertically
              children: [
                Text(
                  'reducio',
                  style: theme.textTheme.displayLarge?.copyWith(
                    // Adjusted shadow for more subtlety if needed
                    shadows: [
                      Shadow(
                        blurRadius: 1.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4), // Spacing between title and tagline
                Text(
                  'Drop. Click. Done.', // Using your new tagline
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.75),
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_tabBarHeight),
          child: Container(
            height: _tabBarHeight,
            alignment: Alignment.center, // Center the TabBar container
            // Optional: color for TabBar background if different from AppBar
            // color: theme.colorScheme.surface.withOpacity(0.1),
            child: Container(
              // Inner container to constrain TabBar width
              constraints: BoxConstraints(maxWidth: _tabBarMaxWidth),

              child: TabBar(
                controller: _tabController,
                // These are now mostly driven by TabBarTheme in main.dart
                // indicatorColor: theme.colorScheme.primary,
                // labelColor: theme.colorScheme.primary,
                // unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
                labelStyle: tabTextStyle?.copyWith(
                    color: theme.colorScheme
                        .primary), // Ensure selected text uses primary
                unselectedLabelStyle: tabTextStyle?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
                indicatorWeight: 2.5,
                indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 0.0), // Let indicator span full tab width
                // labelPadding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding around icon+text
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/compress.png', // Ensure you have these
                          width: 26,
                          height: 26,
                          // Apply color tint based on selection
                          // color: isCompressSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                          // colorBlendMode: BlendMode.srcIn, // Or .modulate if your icons are designed for it
                        ),
                        const SizedBox(width: 8),
                        const Text(
                            'Compress'), // Text style will be inherited from labelStyle/unselectedLabelStyle
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/mute.png', // Ensure you have these
                          width: 26,
                          height: 26,
                          // color: isRemoveAudioSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                          // colorBlendMode: BlendMode.srcIn,
                        ),
                        const SizedBox(width: 8),
                        const Text('Remove Audio'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(
            spaceBetweenBorders, 0, spaceBetweenBorders, spaceBetweenBorders),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: const Color(0xc0837C2F), width: _outerBorderWidth),
                left: BorderSide(
                    color: const Color(0xc0837C2F), width: _outerBorderWidth),
                right: BorderSide(
                    color: const Color(0xc0837C2F), width: _outerBorderWidth))),
        child: Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: const Color(0xc0EDE481), width: _innerBorderWidth),
                  left: BorderSide(
                      color: const Color(0xc0EDE481), width: _innerBorderWidth),
                  right: BorderSide(
                      color: const Color(0xc0EDE481),
                      width: _innerBorderWidth))),
          child: TabBarView(
            controller: _tabController,
            children: const [
              CompressTab(),
              RemoveAudioTab(),
            ],
          ),
        ),
      ),
    );
  }
}
