import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/product.dart';
import '../../repo/product_repo.dart';
import '../../service_locator.dart';
import '../../utils/function_response.dart';
import '../../utils/reusable_widgets.dart';
import '../../view/reuseable/appbar.dart';
import '../../utils/custom_alerts.dart';

class AddProductScreen extends StatelessWidget {
  AddProductScreen({Key? key}) : super(key: key);
  static const routeName = '/add-product-screen';
  final ProductRepo productRepo = getIt<ProductRepo>();

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        appBar: GlobalAppBar(
          screenHeight: screenHeight,
          backwardsCompatibility: true,
        ),
        body: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AddProductWidget(),
                const VerticalDivider(
                  indent: 150,
                  endIndent: 100,
                ),
                ProductList(productRepo: productRepo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  ProductList({
    Key? key,
    required this.productRepo,
  }) : super(key: key);
  final ProductRepo productRepo;
  final CustomAlerts customAlerts = getIt<CustomAlerts>();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocale = AppLocalizations.of(context)!;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              appLocale.recentProducts,
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Product>>(
                  stream: productRepo.watchProducts(),
                  builder: (context, snapshot) {
                    return (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null)
                        ? Center(
                            child: Text(
                              appLocale.noProductFound,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          )
                        : ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final Product currenItem = snapshot.data![index];

                              return Card(
                                key: ValueKey(currenItem.uid),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5.0),
                                  child: Row(children: [
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        currenItem.serialNumber.toString(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        currenItem.name,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () async {
                                            FunctionResponse fResponse =
                                                await customAlerts
                                                    .confirmDelete(
                                                        context: context);
                                            if (fResponse.success) {
                                              productRepo
                                                  .removeProduct(currenItem);
                                            }

                                            customAlerts.showSnackBar(
                                                context,
                                                fResponse.success
                                                    ? 'Deleted Succesfull'
                                                    : 'Delete failed',
                                                success: fResponse.success);
                                          },
                                        ),
                                      ],
                                    )
                                  ]),
                                ),
                              );
                            });
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductWidget extends StatefulWidget {
  AddProductWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<AddProductWidget> createState() => _AddProductWidgetState();
}

class _AddProductWidgetState extends State<AddProductWidget> {
  final TextEditingController nameController = TextEditingController();

  final ProductRepo productRepo = getIt<ProductRepo>();
  final CustomAlerts customAlerts = getIt<CustomAlerts>();

  late FocusNode _txtNode;

  @override
  void initState() {
    super.initState();
    _txtNode = FocusNode();
  }

  @override
  void dispose() {
    _txtNode.dispose();
    super.dispose();
  }

  Future<void> addProduct(
      BuildContext context, AppLocalizations appLocale) async {
    final Product product = Product(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      serialNumber: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      deletedAt: null,
      syncedAt: null,
    );
    final FunctionResponse fResponse = await productRepo.addProduct(product);
    if (fResponse.success) {
      nameController.clear();
    }
    if (mounted) {
      customAlerts.showSnackBar(
          context,
          fResponse.success
              ? appLocale.productAddedSuccessfully
              : appLocale.error,
          success: fResponse.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocale = AppLocalizations.of(context)!;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Focus(
          focusNode: _txtNode,
          onKey: (focusNode, event) {
            if (event.runtimeType == RawKeyUpEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              focusNode.nextFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                appLocale.addProduct,
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 20),
              TextFormField(
                autofocus: true,
                controller: nameController,
                decoration: InputDecoration(
                    labelText: appLocale.name,
                    suffixIcon: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onPressed: () {
                          nameController.clear();
                        },
                        icon: const Icon(Icons.close))),
              ),
              const SizedBox(height: 40),
              customElevatedButton(
                context,
                onPressed: () async {
                  await addProduct(context, appLocale);
                },
                text: appLocale.addProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
