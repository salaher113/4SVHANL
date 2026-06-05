import 'dart:async';
import 'package:flutter/material.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';
import '../models/streamengine/stream_models.dart';
import '../services/streamengine_service.dart';
import '../theme/app_theme.dart';
import 'content_detail_screen.dart';
import '../widgets/common/status_widgets.dart';

class SearchScreen extends StatefulWidget {
  final String type; // 'movie', 'series', or 'all'

  const SearchScreen({super.key, this.type = 'all'});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final NativeTextFieldController _searchController = NativeTextFieldController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final StreamEngineService _service = StreamEngineService();
  List<StreamItem> _results = [];
  bool _isLoading = false;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q == _query) return;
    
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      setState(() {
        _query = q;
      });
      if (q.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final results = await _service.search(_query);
      if (!mounted) return;
      setState(() {
        // Filter by type if needed
        if (widget.type == 'movie') {
          _results = results.whereType<StreamMovie>().toList();
        } else if (widget.type == 'series') {
          _results = results.whereType<StreamTvShow>().toList();
        } else {
          _results = results;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: SizedBox(
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: NativeTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hint: 'Search movies, series...',
              textColor: Colors.white,
              backgroundColor: Colors.transparent,
              height: 48,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 80, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Type to search...',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No results found for "$_query"',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return _ResultCard(item: item);
      },
    );
  }
}

class _ResultCard extends StatefulWidget {
  final StreamItem item;
  const _ResultCard({required this.item});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final poster = widget.item.poster ?? widget.item.banner;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentDetailScreen(
                contentId: widget.item.id,
                isMovie: widget.item is StreamMovie,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: _isFocused
                ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 10)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: poster != null
                ? Image.network(
                    poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallback(),
                  )
                : _buildFallback(),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        widget.item.title,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
