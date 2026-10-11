import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await ApiClient.getNews(limit: 30);

      if (!mounted) return;

      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openArticle(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return;

    final uri = Uri.tryParse(rawUrl);

    if (uri == null || !uri.hasScheme) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    )?.toLocal();

    if (date == null) return '';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        backgroundColor: AppColors.emeraldDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Market News',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.forestGreen,
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 280),
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              )
            : _error != null && _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: FilledButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      28,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      final title =
                          item['title']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? item['title'].toString().trim()
                              : 'Market update';

                      final summary =
                          item['summary']?.toString() ?? '';

                      final source =
                          item['source']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? item['source'].toString().trim()
                              : 'Market News';

                      final date = _date(item['publishedAt']);

                      return Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openArticle(
                            item['url']?.toString(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: Container(
                                          constraints:
                                              const BoxConstraints(
                                            maxWidth: 190,
                                          ),
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.mintTint,
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          child: Text(
                                            source,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color:
                                                  AppColors.forestGreen,
                                              fontSize: 10.5,
                                              fontWeight:
                                                  FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (date.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          date,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 16,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (summary.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    summary.trim(),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Read article',
                                      style: TextStyle(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 15,
                                      color: AppColors.forestGreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}