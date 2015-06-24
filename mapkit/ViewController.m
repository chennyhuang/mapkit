//
//  ViewController.m
//  mapkit
//
//  Created by huangzhenyu on 15/5/19.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import "locationGPS.h"
#import "Myanotation.h"
#import "LocationManager.h"

@interface ViewController ()<MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)backClick:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;//经度
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;//纬度
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    locationGPS *loc = [locationGPS sharedlocationGPS];
    [loc getAuthorization];//授权
    [loc startLocation];//开始定位
    
    //跟踪用户位置
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    //地图类型
//    self.mapView.mapType = MKMapTypeSatellite;
    self.mapView.delegate = self;
    

}

/**
 * 当用户位置更新，就会调用
 *
 * userLocation 表示地图上面那可蓝色的大头针的数据
 */
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D center = userLocation.location.coordinate;
    userLocation.title = [NSString stringWithFormat:@"经度：%f",center.longitude];
    userLocation.subtitle = [NSString stringWithFormat:@"纬度：%f",center.latitude];

    NSLog(@"定位：%f %f --- %i",center.latitude,center.longitude,mapView.showsUserLocation);
    
    if (mapView.showsUserLocation) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            //监听MapView点击
            NSLog(@"添加监听");
            [mapView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
        });
    }
    
    
    //设置地图的中心点，（以用户所在的位置为中心点）
//    [mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
    
    //设置地图的显示范围
//    MKCoordinateSpan span = MKCoordinateSpanMake(0.023666, 0.016093);
//    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
//    [mapView setRegion:region animated:YES];
    
}

//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    //获取跨度
//    NSLog(@"%f  %f",mapView.region.span.latitudeDelta,mapView.region.span.longitudeDelta);
//}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //如果是定位的大头针就不用自定义
    if (![annotation isKindOfClass:[Myanotation class]]) {
        return nil;
    }
    
    static NSString *ID = @"anno";
    MKAnnotationView *annoView = [mapView dequeueReusableAnnotationViewWithIdentifier:ID];
    if (annoView == nil) {
        annoView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
    }
    
    Myanotation *anno = annotation;
    annoView.image = [UIImage imageNamed:@"map_locate_blue"];
    annoView.annotation = anno;
    
    return annoView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didSelectAnnotationView--%@",view);
}

- (IBAction)backClick:(UIButton *)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    CGPoint touchPoint = [tap locationInView:tap.view];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    NSLog(@"%@",self.mapView.annotations);
    NSMutableArray *array = [NSMutableArray array];
    NSUInteger count = self.mapView.annotations.count;
    if (count > 1) {
        for (id obj in self.mapView.annotations) {
            if (![obj isKindOfClass:[MKUserLocation class]]) {
                [array addObject:obj];
            }
        }
        [self.mapView removeAnnotations:array];
    }
    MKUserLocation *locationAnno = self.mapView.annotations[0];
    
    Myanotation *anno = [[Myanotation alloc] init];
    
    anno.coordinate = coordinate;
    anno.title = [NSString stringWithFormat:@"经度：%f",coordinate.longitude];
    anno.subtitle = [NSString stringWithFormat:@"纬度：%f",coordinate.latitude];
    
    self.longitudeLabel.text = [NSString stringWithFormat:@"经度：%f",coordinate.longitude];
    self.latitudeLabel.text = [NSString stringWithFormat:@"纬度：%f",coordinate.latitude];
    //反地理编码
    LocationManager *locManager = [[LocationManager alloc] init];
    [locManager reverseGeocodeWithlatitude:coordinate.latitude longitude:coordinate.longitude success:^(NSString *address) {
        self.addressLabel.text = [NSString stringWithFormat:@"%@",address];
    } failure:^{
        
    }];
    
    //距离
    double distance = [locManager countLineDistanceDest:coordinate.longitude dest_Lat:coordinate.latitude self_Lon:locationAnno.coordinate.longitude self_Lat:locationAnno.coordinate.latitude];
    self.distanceLabel.text = [NSString stringWithFormat:@"距您%d米",(int)distance];
    
    [self.mapView addAnnotation:anno];
    [self.mapView setCenterCoordinate:coordinate animated:YES];
}

@end
