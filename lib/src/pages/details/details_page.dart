import 'dart:collection';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/consts/color_consts.dart';
import 'package:jhentai/src/model/gallery.dart';
import 'package:jhentai/src/model/gallery_details.dart';
import 'package:jhentai/src/model/gallery_image.dart';
import 'package:jhentai/src/routes/routes.dart';
import 'package:jhentai/src/setting/user_setting.dart';
import 'package:jhentai/src/widget/eh_image.dart';
import 'package:jhentai/src/widget/icon_text_button.dart';
import 'package:jhentai/src/widget/loading_state_indicator.dart';

import '../../model/gallery_thumbnail.dart';
import '../../service/download_service.dart';
import '../../utils/date_util.dart';
import '../../widget/gallery_category_tag.dart';
import 'details_page_logic.dart';
import 'details_page_state.dart';

class DetailsPage extends StatelessWidget {
  final DetailsPageLogic detailsPageLogic = Get.put(DetailsPageLogic());

  DetailsPage({Key? key}) : super(key: key);

  final DetailsPageState detailsPageState = Get.find<DetailsPageLogic>().state;

  @override
  Widget build(BuildContext context) {
    Gallery gallery = detailsPageState.gallery!;
    return Scaffold(
      appBar: AppBar(),
      body: GetBuilder<DetailsPageLogic>(builder: (logic) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 0.2,
                color: Get.theme.appBarTheme.foregroundColor!,
              ),
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: detailsPageLogic.handleRefresh),
              _buildHeader(gallery, context),
              _buildDetails(gallery, detailsPageState.galleryDetails),
              _buildActions(gallery, detailsPageState.galleryDetails),
              if (gallery.tags.isNotEmpty) _buildTags(gallery.tags),
              _buildLoadingDetailsIndicator(),
              if (detailsPageState.galleryDetails?.comments.isNotEmpty ?? false)
                _buildComments(detailsPageState.galleryDetails!),
              if (detailsPageState.galleryDetails != null) _buildThumbnails(detailsPageState.galleryDetails!),
              if (detailsPageState.galleryDetails != null) _buildLoadingThumbnailIndicator(),
            ],
          ).paddingOnly(top: 10, left: 15, right: 15),
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: Text('change'),
        onPressed: () {
          // Get.toNamed(Routes.test);
          // Get.changeTheme(Get.isDarkMode ? ThemeConfig.light : ThemeConfig.dark);
          // EHRequest.getUserInfoByCookieAndMemberId(UserSetting.ipbMemberId!);
          Get.find<DownloadService>().downloadGallery(Get.find<DetailsPageLogic>().state.gallery!.toGalleryDownloadedData());
        },
      ),
    );
  }

  Widget _buildHeader(Gallery gallery, BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              GestureDetector(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: EHImage(
                    containerHeight: 200,
                    containerWidth: 140,
                    galleryImage: gallery.cover,
                    adaptive: true,
                    fit: BoxFit.cover,
                  ),
                ),
                onTap: () {
                  Get.toNamed(Routes.singleImagePage, arguments: gallery.cover);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 170,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            gallery.title,
                            minLines: 1,
                            maxLines: 7,
                            style: const TextStyle(fontSize: 16, height: 1.2),
                          ),
                          SelectableText(
                            gallery.uploader,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ).marginOnly(top: 10),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            color: Get.theme.primaryColor,
                            height: 30,
                            width: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CupertinoButton(
                                  child: Text(
                                    'read'.tr,
                                    style: const TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                  color: Get.theme.primaryColor,
                                  borderRadius: BorderRadius.circular(28),
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () => detailsPageLogic.goToReadPage(0),
                                ),
                                Container(
                                  width: 0.4,
                                  color: Colors.white,
                                ),
                                CupertinoButton(
                                  child: Text(
                                    'download'.tr,
                                    style: const TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                  color: Get.theme.primaryColor,
                                  borderRadius: BorderRadius.circular(24),
                                  padding: EdgeInsets.all(0),
                                  onPressed: () => {},
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ).paddingOnly(left: 6),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Gallery gallery, GalleryDetails? galleryDetails) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 18),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        galleryDetails?.realRating.toString() ?? '    ',
                        style: const TextStyle(fontSize: 18),
                      ),
                      RatingBar.builder(
                        unratedColor: Colors.grey.shade300,
                        initialRating: galleryDetails == null ? 0 : gallery.rating,
                        itemCount: 5,
                        allowHalfRating: true,
                        itemSize: 18,
                        ignoreGestures: true,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: gallery.hasRated ? Get.theme.primaryColor : Colors.amber.shade800,
                        ),
                        onRatingUpdate: (rating) {},
                      ).marginOnly(left: 4),
                      Row(
                        children: [
                          Text(
                            galleryDetails?.ratingCount.toString() ?? '',
                            style: const TextStyle(fontSize: 8, color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  ),
                  GalleryCategoryTag(
                    category: gallery.category,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      Text(
                        gallery.language ?? 'Japanese',
                        style: const TextStyle(fontSize: 13),
                      ).marginOnly(left: 2),
                    ],
                  ),
                  Text(
                    galleryDetails?.size ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.collections,
                        size: 12,
                        color: Colors.grey,
                      ),
                      Text(
                        gallery.pageCount.toString(),
                        style: const TextStyle(fontSize: 13),
                      ).marginOnly(left: 2),
                    ],
                  ),
                ],
              ).marginOnly(top: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.red,
                      ),
                      Text(
                        galleryDetails?.favoriteCount.toString() ?? '0',
                        style: const TextStyle(fontSize: 13),
                      ).marginOnly(left: 2),
                    ],
                  ),
                  Text(
                    DateUtil.transform2LocalTimeString(gallery.publishTime),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(Gallery gallery, GalleryDetails? galleryDetails) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 24),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LoadingStateIndicator(
              height: 60,
              width: 76,
              loadingState: detailsPageState.addFavoriteState,
              idleWidget: IconTextButton(
                iconData: gallery.isFavorite && detailsPageState.galleryDetails != null
                    ? Icons.favorite
                    : Icons.favorite_border,
                iconColor: gallery.isFavorite && detailsPageState.galleryDetails != null
                    ? ColorConsts.favoriteTagColor[gallery.favoriteTagIndex!]
                    : null,
                text: Text(
                  gallery.isFavorite ? gallery.favoriteTagName! : 'favorite'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.theme.appBarTheme.titleTextStyle?.color,
                  ),
                ),
                onPressed: detailsPageState.galleryDetails == null
                    ? null
                    : UserSetting.hasLoggedIn()
                        ? detailsPageLogic.handleTapFavorite
                        : detailsPageLogic.showLoginSnack,
              ),
              errorWidgetSameWithIdle: true,
            ),
            IconTextButton(
              height: 60,
              iconData: gallery.hasRated && detailsPageState.galleryDetails != null ? Icons.star : Icons.star_border,
              iconColor: gallery.hasRated && detailsPageState.galleryDetails != null ? Colors.red.shade700 : null,
              text: Text(
                gallery.hasRated ? gallery.rating.toString() : 'rating'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Get.theme.appBarTheme.titleTextStyle?.color,
                ),
              ),
              onPressed: detailsPageState.galleryDetails == null
                  ? null
                  : UserSetting.hasLoggedIn()
                      ? detailsPageLogic.handleTapRating
                      : detailsPageLogic.showLoginSnack,
            ),
            IconTextButton(
              height: 60,
              iconData: FontAwesomeIcons.magnet,
              text: Text(
                'torrent'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Get.theme.appBarTheme.titleTextStyle?.color,
                ),
              ),
              onPressed: () => {},
            ),
            IconTextButton(
              height: 60,
              iconData: Icons.folder_zip,
              text: Text(
                'archive'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Get.theme.appBarTheme.titleTextStyle?.color,
                ),
              ),
              onPressed: () => {},
            ),
            IconTextButton(
              height: 60,
              iconData: Icons.search,
              text: Text(
                'similar'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Get.theme.appBarTheme.titleTextStyle?.color,
                ),
              ),
              onPressed: () => {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(LinkedHashMap<String, List<String>> tagList) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: tagList.entries
              .map(
                (entry) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: ColorConsts.tagCategoryColor[entry.key],
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          entry.key,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
                        ),
                      ),
                    ).marginOnly(right: 10),

                    /// use [expanded] and [wrap] to implement 'flex-wrap'
                    Expanded(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: entry.value
                            .map(
                              (tagName) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.grey.shade200,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Text(
                                    tagName,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ).marginOnly(top: 10),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingDetailsIndicator() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 24),
      sliver: SliverToBoxAdapter(
        child: LoadingStateIndicator(
          indicatorRadius: 16,
          loadingState: detailsPageState.loadingDetailsState,
          errorTapCallback: detailsPageLogic.getDetails,
        ),
      ),
    );
  }

  Widget _buildComments(GalleryDetails galleryDetails) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => {},
                  child: Text(
                    'allComments'.tr,
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemExtent: 300,
              children: galleryDetails.comments
                  .map(
                    (comment) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  comment.userName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Get.theme.primaryColor,
                                  ),
                                ),
                                Text(
                                  comment.time,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 70,
                              child: Text(
                                comment.content,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  comment.score.isNotEmpty ? comment.score : 'uploader'.tr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).paddingSymmetric(vertical: 12, horizontal: 12),
                      ),
                    ).marginOnly(right: 10),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnails(GalleryDetails galleryDetails) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 36),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == galleryDetails.thumbnails.length - 1 &&
              detailsPageState.loadingThumbnailsState == LoadingState.idle) {
            /// 1. shouldn't call directly, because SliverGrid is building, if we call [setState] here will cause a exception
            /// that hints circular build.
            /// 2. when callback is called, the SliverGrid's state will call [setState], it'll rebuild all child by index, it means
            /// that this callback will be added again and again! so add a condition to check loadingState so that make sure
            /// the callback is added once.
            SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
              detailsPageLogic.loadMoreThumbnails();
            });
          }

          GalleryThumbnail thumbnail = galleryDetails.thumbnails[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => detailsPageLogic.goToReadPage(index),
                child: ConstrainedBox(
                  /// 220-16-4
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      /// there's a bug that after cropping, the image's length-width ratio remains(equal to the raw image),
                      /// so choose to assign the size manually.
                      Size imageSize = Size(thumbnail.thumbWidth!, thumbnail.thumbHeight!);
                      Size size = Size(constraints.maxWidth, constraints.maxHeight);
                      FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize, size);

                      return SizedBox(
                        height: fittedSizes.destination.height,
                        width: fittedSizes.destination.width,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ExtendedImage.network(
                            thumbnail.thumbUrl,
                            loadStateChanged: (ExtendedImageState state) {
                              if (state.extendedImageLoadState != LoadState.completed) {
                                return null;
                              }

                              /// crop image because raw image consists of 10 thumbnails in row
                              return ExtendedRawImage(
                                image: state.extendedImageInfo?.image,
                                fit: BoxFit.fill,
                                sourceRect: Rect.fromLTRB(
                                  thumbnail.offSet!,
                                  0,
                                  thumbnail.offSet! + thumbnail.thumbWidth!,
                                  thumbnail.thumbHeight!,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                (index + 1).toString(),
                style: const TextStyle(color: Colors.grey),
              ).paddingOnly(top: 4),
            ],
          );
        }, childCount: galleryDetails.thumbnails.length),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisExtent: 220,
          maxCrossAxisExtent: 150,
          mainAxisSpacing: 20,
          crossAxisSpacing: 5,
        ),
      ),
    );
  }

  Widget _buildLoadingThumbnailIndicator() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      sliver: SliverToBoxAdapter(
        child: LoadingStateIndicator(
          errorTapCallback: () => {detailsPageLogic.loadMoreThumbnails()},
          loadingState: detailsPageState.loadingThumbnailsState,
        ),
      ),
    );
  }
}